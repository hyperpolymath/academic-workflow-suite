defmodule AwapBackend.Moodle.SyncScheduler do
  @moduledoc """
  Periodically synchronizes data from Moodle LMS.

  Runs scheduled tasks to:
  - Fetch new TMA submissions
  - Update assignment metadata
  - Sync grades and feedback back to Moodle

  The sync interval is configurable via application config.

  ## Configuration

      config :awap_backend, :moodle_sync_interval, :timer.minutes(15)
      config :awap_backend, :moodle_username, "service_account"
      config :awap_backend, :moodle_password, "secure_password"
  """

  use GenServer
  require Logger

  alias AwapBackend.Moodle
  alias AwapBackend.Repo
  alias AwapBackend.Schemas.{Course, Submission, TMA}

  import Ecto.Query

  @default_interval :timer.minutes(15)

  defstruct [:interval, :timer_ref, :last_sync, :sync_in_progress]

  # Client API

  @doc """
  Starts the Moodle sync scheduler.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Triggers an immediate sync.
  """
  def sync_now do
    GenServer.cast(__MODULE__, :sync_now)
  end

  @doc """
  Gets the last sync timestamp.
  """
  def last_sync do
    GenServer.call(__MODULE__, :last_sync)
  end

  @doc """
  Gets the current sync status.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    interval = Application.get_env(:awap_backend, :moodle_sync_interval, @default_interval)

    state = %__MODULE__{
      interval: interval,
      timer_ref: nil,
      last_sync: nil,
      sync_in_progress: false
    }

    # Schedule first sync
    {:ok, schedule_sync(state)}
  end

  @impl true
  def handle_cast(:sync_now, %{sync_in_progress: true} = state) do
    Logger.warning("Sync already in progress, ignoring sync_now request")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:sync_now, state) do
    # Cancel existing timer
    state = cancel_timer(state)

    # Start sync in background task
    Task.start(fn -> perform_sync() end)

    # Reschedule
    new_state = %{state | last_sync: DateTime.utc_now(), sync_in_progress: true}
    {:noreply, schedule_sync(new_state)}
  end

  @impl true
  def handle_info(:perform_sync, %{sync_in_progress: true} = state) do
    Logger.debug("Skipping scheduled sync, previous sync still in progress")
    {:noreply, schedule_sync(state)}
  end

  @impl true
  def handle_info(:perform_sync, state) do
    Logger.info("Starting scheduled Moodle sync")

    # Run sync in a monitored task
    parent = self()

    Task.start(fn ->
      result = perform_sync()
      send(parent, {:sync_complete, result})
    end)

    new_state = %{state | sync_in_progress: true}
    {:noreply, schedule_sync(new_state)}
  end

  @impl true
  def handle_info({:sync_complete, result}, state) do
    case result do
      :ok ->
        Logger.info("Moodle sync completed successfully")

      {:error, reason} ->
        Logger.error("Moodle sync completed with error: #{inspect(reason)}")
    end

    {:noreply, %{state | last_sync: DateTime.utc_now(), sync_in_progress: false}}
  end

  @impl true
  def handle_call(:last_sync, _from, state) do
    {:reply, state.last_sync, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      last_sync: state.last_sync,
      sync_in_progress: state.sync_in_progress,
      interval_minutes: div(state.interval, 60_000)
    }

    {:reply, status, state}
  end

  # Private Functions

  defp schedule_sync(state) do
    # Cancel existing timer if any
    state = cancel_timer(state)

    # Schedule next sync
    timer_ref = Process.send_after(self(), :perform_sync, state.interval)
    %{state | timer_ref: timer_ref}
  end

  defp cancel_timer(%{timer_ref: nil} = state), do: state

  defp cancel_timer(%{timer_ref: timer_ref} = state) do
    Process.cancel_timer(timer_ref)
    %{state | timer_ref: nil}
  end

  defp perform_sync do
    with {:ok, token} <- get_moodle_token(),
         {:ok, courses} <- get_active_courses(),
         :ok <- sync_courses(token, courses) do
      Logger.info("Moodle sync completed successfully")
      :ok
    else
      {:error, reason} ->
        Logger.error("Moodle sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_moodle_token do
    # Retrieve stored token or authenticate
    # In production, this would use a credential store
    username = Application.get_env(:awap_backend, :moodle_username)
    password = Application.get_env(:awap_backend, :moodle_password)

    if username && password do
      Moodle.authenticate_oauth2(username, password)
    else
      {:error, :credentials_not_configured}
    end
  end

  defp get_active_courses do
    # Query courses with sync enabled from the database
    query =
      from c in Course,
        where: c.sync_enabled == true,
        select: %{id: c.moodle_id, name: c.name, db_id: c.id}

    courses = Repo.all(query)

    Logger.debug("Found #{length(courses)} courses to sync")
    {:ok, courses}
  end

  defp sync_courses(_token, []), do: :ok

  defp sync_courses(token, courses) do
    results =
      Enum.map(courses, fn course ->
        case sync_course(token, course) do
          :ok ->
            update_course_sync_timestamp(course.db_id)
            {:ok, course.id}

          {:error, reason} ->
            {:error, course.id, reason}
        end
      end)

    errors = Enum.filter(results, &match?({:error, _, _}, &1))

    if Enum.empty?(errors) do
      :ok
    else
      {:error, {:partial_sync_failure, errors}}
    end
  end

  defp update_course_sync_timestamp(course_db_id) do
    case Repo.get(Course, course_db_id) do
      nil ->
        Logger.warning("Course not found for sync timestamp update: #{course_db_id}")

      course ->
        course
        |> Course.sync_changeset()
        |> Repo.update()
    end
  end

  defp sync_course(token, course) do
    with {:ok, assignments} <- Moodle.get_assignments(token, course.id),
         :ok <- sync_assignments(token, course, assignments) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to sync course #{course.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_assignments(_token, _course, []), do: :ok

  defp sync_assignments(token, course, assignments) do
    Enum.reduce_while(assignments, :ok, fn assignment, _acc ->
      case sync_assignment(token, course, assignment) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp sync_assignment(token, course, assignment) do
    Logger.debug("Syncing assignment #{assignment.id}")

    with {:ok, submissions} <- Moodle.download_submissions(token, assignment.id),
         :ok <- process_submissions(course, assignment, submissions) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to sync assignment #{assignment.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp process_submissions(_course, _assignment, []) do
    Logger.debug("No submissions to process")
    :ok
  end

  defp process_submissions(course, assignment, submissions) do
    Logger.info("Processing #{length(submissions)} submissions for assignment #{assignment.id}")

    results =
      Enum.map(submissions, fn submission ->
        process_single_submission(course, assignment, submission)
      end)

    successful = Enum.count(results, &match?({:ok, _}, &1))
    failed = Enum.count(results, &match?({:error, _}, &1))

    Logger.info(
      "Processed #{successful} submissions successfully, #{failed} failed for assignment #{assignment.id}"
    )

    if failed > 0 do
      {:error, {:partial_failure, failed}}
    else
      :ok
    end
  end

  defp process_single_submission(course, assignment, submission) do
    # Check if submission already exists
    existing =
      Repo.get_by(Submission,
        moodle_submission_id: submission.id,
        moodle_assignment_id: assignment.id
      )

    case existing do
      nil ->
        # Create new submission record
        create_submission(course, assignment, submission)

      %Submission{status: :uploaded} ->
        # Already processed and uploaded, skip
        {:ok, :skipped}

      existing_submission ->
        # Update existing submission if needed
        update_submission(existing_submission, submission)
    end
  end

  defp create_submission(course, assignment, submission) do
    attrs = %{
      moodle_submission_id: submission.id,
      moodle_assignment_id: assignment.id,
      moodle_user_id: submission.user_id,
      course_id: course.db_id,
      status: :downloaded,
      submitted_at: submission.submitted_at,
      files: submission.files || [],
      raw_data: submission
    }

    %Submission{}
    |> Submission.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, saved_submission} ->
        # Create corresponding TMA for processing
        create_tma_from_submission(course, assignment, saved_submission)

      {:error, changeset} ->
        Logger.error("Failed to create submission: #{inspect(changeset.errors)}")
        {:error, changeset.errors}
    end
  end

  defp update_submission(existing, new_data) do
    # Update if submission status has changed in Moodle
    if existing.raw_data != new_data do
      existing
      |> Submission.changeset(%{raw_data: new_data, files: new_data.files || []})
      |> Repo.update()
    else
      {:ok, :unchanged}
    end
  end

  defp create_tma_from_submission(course, assignment, submission) do
    # Convert Moodle submission to TMA for AI processing
    tma_attrs = %{
      assignment_id: to_string(assignment.id),
      student_id: to_string(submission.moodle_user_id),
      course_id: to_string(course.id),
      content: %{
        files: submission.files,
        raw_submission: submission.raw_data,
        assignment_name: assignment.name,
        assignment_description: assignment.description
      },
      status: :pending,
      submitted_at: submission.submitted_at
    }

    case %TMA{} |> TMA.changeset(tma_attrs) |> Repo.insert() do
      {:ok, tma} ->
        # Link TMA to submission
        submission
        |> Submission.changeset(%{tma_id: tma.id, status: :processing})
        |> Repo.update()

        {:ok, tma}

      {:error, changeset} ->
        Logger.error("Failed to create TMA: #{inspect(changeset.errors)}")
        {:error, changeset.errors}
    end
  end
end
