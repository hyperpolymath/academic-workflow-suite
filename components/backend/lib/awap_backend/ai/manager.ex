defmodule AwapBackend.AI.Manager do
  @moduledoc """
  AI Jail Manager for Podman container lifecycle management.

  Manages isolated AI containers (jails) that process feedback generation requests.
  Each container runs in a restricted environment with:
  - Network isolation
  - Resource limits (CPU, memory)
  - Read-only filesystem where possible
  - Time limits for processing

  ## Container Lifecycle

  1. Start: `podman run` with security constraints
  2. Health: Monitor container health
  3. Process: Route feedback requests to container
  4. Stop: Clean shutdown or force kill after timeout

  ## Configuration

      config :awap_backend, AwapBackend.AI.Manager,
        container_image: "localhost/awap-ai:latest",
        max_containers: 5,
        max_memory: "2g",
        max_cpus: "1.0",
        network_mode: "none"

  ## Security Considerations

  - Containers run as non-root user
  - No network access (network_mode: none)
  - CPU and memory limits enforced
  - Containers are ephemeral (removed after use)
  - Processing timeout prevents runaway containers
  """

  use GenServer
  require Logger

  alias AwapBackend.AI.Container

  defstruct [:max_containers, :active_containers, :container_queue]

  @type container_id :: String.t()
  @type feedback_request :: %{
          tma_id: String.t(),
          content: map(),
          timeout: integer()
        }

  # Client API

  @doc """
  Starts the AI Manager.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a new AI container.

  Returns `{:ok, container_id}` or `{:error, reason}`.
  """
  @spec start_container() :: {:ok, container_id()} | {:error, term()}
  def start_container do
    GenServer.call(__MODULE__, :start_container)
  end

  @doc """
  Stops an AI container.
  """
  @spec stop_container(container_id()) :: :ok | {:error, term()}
  def stop_container(container_id) do
    GenServer.call(__MODULE__, {:stop_container, container_id})
  end

  @doc """
  Routes a feedback generation request to an available container.

  If no containers are available, queues the request.
  """
  @spec request_feedback(feedback_request()) :: {:ok, String.t()} | {:error, term()}
  def request_feedback(request) do
    GenServer.call(__MODULE__, {:request_feedback, request}, :infinity)
  end

  @doc """
  Lists all active containers.
  """
  @spec list_containers() :: list(map())
  def list_containers do
    GenServer.call(__MODULE__, :list_containers)
  end

  @doc """
  Health check for all active containers.
  """
  @spec health_check() :: map()
  def health_check do
    GenServer.call(__MODULE__, :health_check)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    max_containers = get_max_containers()

    state = %__MODULE__{
      max_containers: max_containers,
      active_containers: %{},
      container_queue: :queue.new()
    }

    # Start initial container pool
    {:ok, state, {:continue, :initialize_pool}}
  end

  @impl true
  def handle_continue(:initialize_pool, state) do
    Logger.info("Initializing AI container pool (max: #{state.max_containers})")

    # Start one container initially (can scale up on demand)
    case Container.start() do
      {:ok, container_id} ->
        containers = Map.put(state.active_containers, container_id, %{
          started_at: DateTime.utc_now(),
          status: :ready,
          requests_processed: 0
        })

        Logger.info("Started initial AI container: #{container_id}")
        {:noreply, %{state | active_containers: containers}}

      {:error, reason} ->
        Logger.error("Failed to start initial container: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:start_container, _from, state) do
    if map_size(state.active_containers) >= state.max_containers do
      {:reply, {:error, :max_containers_reached}, state}
    else
      case Container.start() do
        {:ok, container_id} ->
          containers = Map.put(state.active_containers, container_id, %{
            started_at: DateTime.utc_now(),
            status: :ready,
            requests_processed: 0
          })

          Logger.info("Started AI container: #{container_id}")
          {:reply, {:ok, container_id}, %{state | active_containers: containers}}

        {:error, reason} = error ->
          Logger.error("Failed to start container: #{inspect(reason)}")
          {:reply, error, state}
      end
    end
  end

  @impl true
  def handle_call({:stop_container, container_id}, _from, state) do
    case Container.stop(container_id) do
      :ok ->
        containers = Map.delete(state.active_containers, container_id)
        Logger.info("Stopped AI container: #{container_id}")
        {:reply, :ok, %{state | active_containers: containers}}

      {:error, reason} = error ->
        Logger.error("Failed to stop container #{container_id}: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:request_feedback, request}, from, state) do
    case find_available_container(state.active_containers) do
      {:ok, container_id} ->
        # Process request asynchronously
        Task.start(fn ->
          result = Container.process_feedback(container_id, request)
          GenServer.reply(from, result)
        end)

        # Update container status
        containers = update_container_status(state.active_containers, container_id, :processing)
        {:noreply, %{state | active_containers: containers}}

      :error ->
        # No available containers, queue the request
        queue = :queue.in({from, request}, state.container_queue)
        {:noreply, %{state | container_queue: queue}}
    end
  end

  @impl true
  def handle_call(:list_containers, _from, state) do
    containers =
      Enum.map(state.active_containers, fn {id, info} ->
        %{
          container_id: id,
          status: info.status,
          started_at: info.started_at,
          requests_processed: info.requests_processed
        }
      end)

    {:reply, containers, state}
  end

  @impl true
  def handle_call(:health_check, _from, state) do
    health =
      Enum.map(state.active_containers, fn {id, _info} ->
        {id, Container.health_check(id)}
      end)
      |> Enum.into(%{})

    result = %{
      total_containers: map_size(state.active_containers),
      max_containers: state.max_containers,
      queued_requests: :queue.len(state.container_queue),
      container_health: health
    }

    {:reply, result, state}
  end

  @impl true
  def handle_info({:container_ready, container_id}, state) do
    # Container finished processing, mark as ready
    containers = update_container_status(state.active_containers, container_id, :ready)

    # Process queued request if any
    case :queue.out(state.container_queue) do
      {{:value, {from, request}}, new_queue} ->
        Task.start(fn ->
          result = Container.process_feedback(container_id, request)
          GenServer.reply(from, result)
        end)

        containers = update_container_status(containers, container_id, :processing)
        {:noreply, %{state | active_containers: containers, container_queue: new_queue}}

      {:empty, _queue} ->
        {:noreply, %{state | active_containers: containers}}
    end
  end

  @impl true
  def handle_info({:container_failed, container_id, reason}, state) do
    Logger.error("Container #{container_id} failed: #{inspect(reason)}")

    # Remove failed container
    containers = Map.delete(state.active_containers, container_id)

    # Attempt to start a replacement
    case Container.start() do
      {:ok, new_container_id} ->
        containers = Map.put(containers, new_container_id, %{
          started_at: DateTime.utc_now(),
          status: :ready,
          requests_processed: 0
        })

        Logger.info("Started replacement container: #{new_container_id}")
        {:noreply, %{state | active_containers: containers}}

      {:error, start_reason} ->
        Logger.error("Failed to start replacement container: #{inspect(start_reason)}")
        {:noreply, %{state | active_containers: containers}}
    end
  end

  # Private Functions

  defp get_max_containers do
    Application.get_env(:awap_backend, __MODULE__, [])
    |> Keyword.get(:max_containers, 5)
  end

  defp find_available_container(containers) do
    Enum.find_value(containers, :error, fn {id, info} ->
      if info.status == :ready, do: {:ok, id}, else: nil
    end)
  end

  defp update_container_status(containers, container_id, new_status) do
    Map.update(containers, container_id, %{}, fn info ->
      info = Map.put(info, :status, new_status)

      if new_status == :ready do
        Map.update(info, :requests_processed, 0, &(&1 + 1))
      else
        info
      end
    end)
  end
end
