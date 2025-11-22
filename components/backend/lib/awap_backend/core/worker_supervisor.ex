defmodule AwapBackend.CoreEngine.WorkerSupervisor do
  @moduledoc """
  Supervises the pool of core engine workers.

  Dynamically manages worker processes and provides checkout/checkin semantics
  for distributing work across the pool.
  """

  use DynamicSupervisor
  require Logger

  @doc """
  Starts the worker supervisor.
  """
  def start_link(opts) do
    pool_size = Keyword.get(opts, :pool_size, 10)
    DynamicSupervisor.start_link(__MODULE__, pool_size, name: __MODULE__)
  end

  @doc """
  Checks out an available worker from the pool.
  """
  @spec checkout() :: {:ok, pid()} | :error
  def checkout do
    workers = list_workers()

    Enum.find_value(workers, :error, fn {_id, pid, _type, _modules} ->
      case AwapBackend.CoreEngine.Worker.status(pid) do
        %{status: :idle} -> {:ok, pid}
        _ -> nil
      end
    end)
  end

  @doc """
  Lists all worker processes.
  """
  def list_workers do
    DynamicSupervisor.which_children(__MODULE__)
  end

  @impl true
  def init(pool_size) do
    # Start worker registry
    Registry.start_link(keys: :unique, name: AwapBackend.CoreEngine.WorkerRegistry)

    # Start initial workers
    for i <- 1..pool_size do
      worker_id = "worker_#{i}"
      start_worker(worker_id)
    end

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_worker(worker_id) do
    spec = %{
      id: worker_id,
      start: {AwapBackend.CoreEngine.Worker, :start_link, [[worker_id: worker_id]]},
      restart: :permanent
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} ->
        Logger.debug("Started worker #{worker_id}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to start worker #{worker_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
