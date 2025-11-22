defmodule AwapBackend.CoreEngine.WorkerPool do
  @moduledoc """
  Worker pool for managing concurrent TMA processing tasks.

  Maintains a pool of worker processes that interact with the Rust core engine
  to process TMAs. Uses poolboy or similar pooling strategy to limit concurrency
  and prevent resource exhaustion.
  """

  use Supervisor
  require Logger

  @doc """
  Starts the worker pool supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Submits a TMA for processing by the core engine.

  Returns `{:ok, job_id}` immediately and processes asynchronously.
  """
  @spec process_tma(String.t(), map()) :: {:ok, String.t()} | {:error, term()}
  def process_tma(tma_id, tma_data) do
    job_id = generate_job_id()

    case checkout_worker() do
      {:ok, worker} ->
        Task.Supervisor.start_child(AwapBackend.CoreEngine.TaskSupervisor, fn ->
          AwapBackend.CoreEngine.Worker.process(worker, tma_id, tma_data, job_id)
        end)

        {:ok, job_id}

      {:error, :no_workers_available} ->
        {:error, :pool_exhausted}
    end
  end

  @doc """
  Gets the status of a processing job.
  """
  @spec job_status(String.t()) :: {:ok, map()} | {:error, :not_found}
  def job_status(job_id) do
    # Query job status from persistent storage or cache
    AwapBackend.CoreEngine.JobRegistry.get(job_id)
  end

  @impl true
  def init(opts) do
    pool_size = Keyword.get(opts, :pool_size, 10)

    children = [
      # Task supervisor for async TMA processing
      {Task.Supervisor, name: AwapBackend.CoreEngine.TaskSupervisor},

      # Job registry for tracking processing jobs
      {AwapBackend.CoreEngine.JobRegistry, []},

      # Worker pool
      {AwapBackend.CoreEngine.WorkerSupervisor, pool_size: pool_size}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp checkout_worker do
    case AwapBackend.CoreEngine.WorkerSupervisor.checkout() do
      {:ok, worker} -> {:ok, worker}
      :error -> {:error, :no_workers_available}
    end
  end

  defp generate_job_id do
    Ecto.UUID.generate()
  end
end
