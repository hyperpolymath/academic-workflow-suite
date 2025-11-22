defmodule AwapBackend.CoreEngine.Worker do
  @moduledoc """
  Individual worker process for TMA processing.

  Communicates with the Rust core engine via NIF or Port to:
  - Anonymize student information
  - Parse TMA submissions
  - Generate marking feedback
  - Store processing events
  """

  use GenServer
  require Logger

  alias AwapBackend.CoreBridge

  defstruct [:worker_id, :status, :current_job]

  @type t :: %__MODULE__{
          worker_id: String.t(),
          status: :idle | :busy,
          current_job: String.t() | nil
        }

  # Client API

  @doc """
  Starts a worker process.
  """
  def start_link(opts) do
    worker_id = Keyword.fetch!(opts, :worker_id)
    GenServer.start_link(__MODULE__, worker_id, name: via_tuple(worker_id))
  end

  @doc """
  Processes a TMA using this worker.
  """
  @spec process(GenServer.server(), String.t(), map(), String.t()) :: :ok | {:error, term()}
  def process(worker, tma_id, tma_data, job_id) do
    GenServer.call(worker, {:process, tma_id, tma_data, job_id}, :infinity)
  end

  @doc """
  Gets the current status of this worker.
  """
  def status(worker) do
    GenServer.call(worker, :status)
  end

  # Server Callbacks

  @impl true
  def init(worker_id) do
    state = %__MODULE__{
      worker_id: worker_id,
      status: :idle,
      current_job: nil
    }

    Logger.info("Core worker #{worker_id} started")
    {:ok, state}
  end

  @impl true
  def handle_call({:process, tma_id, tma_data, job_id}, _from, state) do
    Logger.info("Worker #{state.worker_id} processing TMA #{tma_id}, job #{job_id}")

    # Update state to busy
    new_state = %{state | status: :busy, current_job: job_id}

    # Process TMA through Rust core
    result =
      with {:ok, anonymized_data} <- CoreBridge.anonymize_student(tma_data),
           {:ok, parsed_tma} <- CoreBridge.parse_tma(anonymized_data),
           {:ok, feedback} <- CoreBridge.generate_feedback(parsed_tma),
           :ok <- store_results(tma_id, job_id, feedback) do
        Logger.info("Worker #{state.worker_id} completed TMA #{tma_id}")
        :ok
      else
        {:error, reason} = error ->
          Logger.error("Worker #{state.worker_id} failed processing TMA #{tma_id}: #{inspect(reason)}")
          store_error(tma_id, job_id, reason)
          error
      end

    # Return to idle
    idle_state = %{new_state | status: :idle, current_job: nil}
    {:reply, result, idle_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status_info = %{
      worker_id: state.worker_id,
      status: state.status,
      current_job: state.current_job
    }

    {:reply, status_info, state}
  end

  # Private Functions

  defp via_tuple(worker_id) do
    {:via, Registry, {AwapBackend.CoreEngine.WorkerRegistry, worker_id}}
  end

  defp store_results(tma_id, job_id, feedback) do
    # Store results in database
    case AwapBackend.TMA.update_with_feedback(tma_id, job_id, feedback) do
      {:ok, _tma} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp store_error(tma_id, job_id, reason) do
    AwapBackend.TMA.update_with_error(tma_id, job_id, reason)
  end
end
