defmodule AwapBackend.Moodle.SyncScheduler do
  @moduledoc """
  Periodically synchronizes data from Moodle LMS.

  Runs scheduled tasks to:
  - Fetch new TMA submissions
  - Update assignment metadata
  - Sync grades and feedback back to Moodle

  The sync interval is configurable via application config.
  """

  use GenServer
  require Logger

  alias AwapBackend.Moodle

  @default_interval :timer.minutes(15)

  defstruct [:interval, :timer_ref, :last_sync]

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

  # Server Callbacks

  @impl true
  def init(_opts) do
    interval = Application.get_env(:awap_backend, :moodle_sync_interval, @default_interval)

    state = %__MODULE__{
      interval: interval,
      timer_ref: nil,
      last_sync: nil
    }

    # Schedule first sync
    {:ok, schedule_sync(state)}
  end

  @impl true
  def handle_cast(:sync_now, state) do
    # Cancel existing timer
    state = cancel_timer(state)

    # Perform sync
    perform_sync()

    # Reschedule
    new_state = %{state | last_sync: DateTime.utc_now()}
    {:noreply, schedule_sync(new_state)}
  end

  @impl true
  def handle_info(:perform_sync, state) do
    Logger.info("Starting scheduled Moodle sync")
    perform_sync()

    new_state = %{state | last_sync: DateTime.utc_now()}
    {:noreply, schedule_sync(new_state)}
  end

  @impl true
  def handle_call(:last_sync, _from, state) do
    {:reply, state.last_sync, state}
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
    # Get list of courses to sync from database
    # This is a stub - would query from database in production
    {:ok, []}
  end

  defp sync_courses(_token, []), do: :ok

  defp sync_courses(token, courses) do
    Enum.reduce_while(courses, :ok, fn course, _acc ->
      case sync_course(token, course) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp sync_course(token, course) do
    with {:ok, assignments} <- Moodle.get_assignments(token, course.id),
         :ok <- sync_assignments(token, assignments) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to sync course #{course.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_assignments(_token, []), do: :ok

  defp sync_assignments(token, assignments) do
    Enum.reduce_while(assignments, :ok, fn assignment, _acc ->
      case sync_assignment(token, assignment) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp sync_assignment(token, assignment) do
    Logger.debug("Syncing assignment #{assignment.id}")

    with {:ok, submissions} <- Moodle.download_submissions(token, assignment.id),
         :ok <- process_submissions(submissions) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to sync assignment #{assignment.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp process_submissions(submissions) do
    # Store submissions in database
    # This is a stub - would use Ecto in production
    Logger.debug("Processing #{length(submissions)} submissions")
    :ok
  end
end
