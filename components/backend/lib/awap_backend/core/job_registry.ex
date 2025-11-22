defmodule AwapBackend.CoreEngine.JobRegistry do
  @moduledoc """
  Registry for tracking TMA processing jobs.

  Maintains in-memory state of active jobs with periodic persistence to the database.
  Provides fast lookups for job status queries.
  """

  use GenServer
  require Logger

  @type job_status :: :queued | :processing | :completed | :failed

  @type job :: %{
          job_id: String.t(),
          tma_id: String.t(),
          status: job_status(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          error: String.t() | nil
        }

  # Client API

  @doc """
  Starts the job registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a new job.
  """
  @spec register(String.t(), String.t()) :: :ok
  def register(job_id, tma_id) do
    GenServer.cast(__MODULE__, {:register, job_id, tma_id})
  end

  @doc """
  Updates job status.
  """
  @spec update_status(String.t(), job_status(), keyword()) :: :ok
  def update_status(job_id, status, opts \\ []) do
    GenServer.cast(__MODULE__, {:update_status, job_id, status, opts})
  end

  @doc """
  Gets job information.
  """
  @spec get(String.t()) :: {:ok, job()} | {:error, :not_found}
  def get(job_id) do
    GenServer.call(__MODULE__, {:get, job_id})
  end

  @doc """
  Lists all jobs, optionally filtered by status.
  """
  @spec list(keyword()) :: list(job())
  def list(opts \\ []) do
    GenServer.call(__MODULE__, {:list, opts})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Initialize ETS table for fast lookups
    :ets.new(:job_registry, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:register, job_id, tma_id}, state) do
    job = %{
      job_id: job_id,
      tma_id: tma_id,
      status: :queued,
      started_at: nil,
      completed_at: nil,
      error: nil
    }

    :ets.insert(:job_registry, {job_id, job})
    Logger.debug("Registered job #{job_id} for TMA #{tma_id}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_status, job_id, status, opts}, state) do
    case :ets.lookup(:job_registry, job_id) do
      [{^job_id, job}] ->
        updated_job =
          job
          |> Map.put(:status, status)
          |> maybe_set_started_at(status)
          |> maybe_set_completed_at(status)
          |> maybe_set_error(Keyword.get(opts, :error))

        :ets.insert(:job_registry, {job_id, updated_job})
        Logger.debug("Updated job #{job_id} status to #{status}")

      [] ->
        Logger.warn("Attempted to update non-existent job #{job_id}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:get, job_id}, _from, state) do
    result =
      case :ets.lookup(:job_registry, job_id) do
        [{^job_id, job}] -> {:ok, job}
        [] -> {:error, :not_found}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:list, opts}, _from, state) do
    filter_status = Keyword.get(opts, :status)

    jobs =
      :ets.tab2list(:job_registry)
      |> Enum.map(fn {_id, job} -> job end)
      |> maybe_filter_by_status(filter_status)

    {:reply, jobs, state}
  end

  # Private Functions

  defp maybe_set_started_at(job, :processing) do
    Map.put(job, :started_at, DateTime.utc_now())
  end

  defp maybe_set_started_at(job, _), do: job

  defp maybe_set_completed_at(job, status) when status in [:completed, :failed] do
    Map.put(job, :completed_at, DateTime.utc_now())
  end

  defp maybe_set_completed_at(job, _), do: job

  defp maybe_set_error(job, nil), do: job

  defp maybe_set_error(job, error) do
    Map.put(job, :error, to_string(error))
  end

  defp maybe_filter_by_status(jobs, nil), do: jobs

  defp maybe_filter_by_status(jobs, status) do
    Enum.filter(jobs, &(&1.status == status))
  end
end
