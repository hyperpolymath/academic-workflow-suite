defmodule AwapBackend.EventStore do
  @moduledoc """
  Event Store connection manager for event sourcing.

  Maintains a persistent connection to the event store (EventStoreDB or similar)
  and provides an interface for querying and appending events.

  The event store is used by the Rust core engine to maintain an audit trail
  of all TMA processing activities, including submissions, anonymization,
  marking, and feedback generation.
  """

  use GenServer
  require Logger

  @type event :: %{
          event_type: String.t(),
          data: map(),
          metadata: map(),
          timestamp: DateTime.t()
        }

  # Client API

  @doc """
  Starts the EventStore connection.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Appends an event to the event store.
  """
  @spec append_event(String.t(), event()) :: :ok | {:error, term()}
  def append_event(stream_id, event) do
    GenServer.call(__MODULE__, {:append, stream_id, event})
  end

  @doc """
  Reads events from a stream.
  """
  @spec read_stream(String.t(), keyword()) :: {:ok, list(event())} | {:error, term()}
  def read_stream(stream_id, opts \\ []) do
    GenServer.call(__MODULE__, {:read, stream_id, opts})
  end

  @doc """
  Subscribes to events from a stream.
  """
  @spec subscribe(String.t()) :: :ok | {:error, term()}
  def subscribe(stream_id) do
    GenServer.call(__MODULE__, {:subscribe, stream_id})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    connection_string = Application.get_env(:awap_backend, :event_store_url)

    state = %{
      connection: nil,
      connection_string: connection_string,
      subscriptions: %{}
    }

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    case connect(state.connection_string) do
      {:ok, conn} ->
        Logger.info("EventStore connected successfully")
        {:noreply, %{state | connection: conn}}

      {:error, reason} ->
        Logger.error("Failed to connect to EventStore: #{inspect(reason)}")
        # Retry connection after 5 seconds
        Process.send_after(self(), :retry_connect, 5_000)
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:append, stream_id, event}, _from, state) do
    case append_to_store(state.connection, stream_id, event) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} = error ->
        Logger.error("Failed to append event to stream #{stream_id}: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:read, stream_id, opts}, _from, state) do
    case read_from_store(state.connection, stream_id, opts) do
      {:ok, events} ->
        {:reply, {:ok, events}, state}

      {:error, reason} = error ->
        Logger.error("Failed to read from stream #{stream_id}: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:subscribe, stream_id}, {pid, _ref}, state) do
    subscriptions = Map.update(state.subscriptions, stream_id, [pid], &[pid | &1])
    {:reply, :ok, %{state | subscriptions: subscriptions}}
  end

  @impl true
  def handle_info(:retry_connect, state) do
    case connect(state.connection_string) do
      {:ok, conn} ->
        Logger.info("EventStore reconnected successfully")
        {:noreply, %{state | connection: conn}}

      {:error, reason} ->
        Logger.error("Failed to reconnect to EventStore: #{inspect(reason)}")
        Process.send_after(self(), :retry_connect, 5_000)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:event, stream_id, event}, state) do
    # Notify all subscribers
    subscribers = Map.get(state.subscriptions, stream_id, [])

    Enum.each(subscribers, fn pid ->
      send(pid, {:event_store_event, stream_id, event})
    end)

    {:noreply, state}
  end

  # Private Functions

  defp connect(connection_string) do
    # TODO: Implement actual EventStore connection
    # This is a stub that would connect to EventStoreDB, PostgreSQL event log, or similar
    Logger.debug("Connecting to EventStore at #{connection_string}")
    {:ok, %{connected: true, url: connection_string}}
  end

  defp append_to_store(_connection, stream_id, event) do
    # TODO: Implement actual event appending
    Logger.debug("Appending event to stream #{stream_id}: #{inspect(event)}")
    :ok
  end

  defp read_from_store(_connection, stream_id, _opts) do
    # TODO: Implement actual event reading
    Logger.debug("Reading events from stream #{stream_id}")
    {:ok, []}
  end
end
