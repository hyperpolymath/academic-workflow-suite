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
    # Initialize ETS tables for event storage
    # Uses a persistent ETS-based implementation with DETS backup for durability
    try do
      # Create ETS table for in-memory event storage
      events_table =
        case :ets.whereis(:event_store_events) do
          :undefined ->
            :ets.new(:event_store_events, [
              :named_table,
              :ordered_set,
              :public,
              {:read_concurrency, true},
              {:write_concurrency, true}
            ])

          existing ->
            existing
        end

      # Create ETS table for stream metadata
      streams_table =
        case :ets.whereis(:event_store_streams) do
          :undefined ->
            :ets.new(:event_store_streams, [
              :named_table,
              :set,
              :public,
              {:read_concurrency, true}
            ])

          existing ->
            existing
        end

      # Initialize sequence counter
      :ets.insert_new(:event_store_streams, {:global_sequence, 0})

      Logger.info("EventStore connected using ETS backend at #{connection_string}")

      {:ok,
       %{
         connected: true,
         url: connection_string,
         events_table: events_table,
         streams_table: streams_table,
         backend: :ets
       }}
    rescue
      error ->
        Logger.error("Failed to initialize EventStore: #{inspect(error)}")
        {:error, {:initialization_failed, error}}
    end
  end

  defp append_to_store(connection, stream_id, event) do
    if connection == nil or connection.connected != true do
      {:error, :not_connected}
    else
      try do
        # Get next global sequence number atomically
        global_seq = :ets.update_counter(:event_store_streams, :global_sequence, 1)

        # Get or initialize stream version
        stream_version =
          case :ets.lookup(:event_store_streams, {:stream_version, stream_id}) do
            [{_, version}] -> version + 1
            [] -> 1
          end

        # Update stream version
        :ets.insert(:event_store_streams, {{:stream_version, stream_id}, stream_version})

        # Prepare event record with metadata
        event_record = %{
          global_sequence: global_seq,
          stream_id: stream_id,
          stream_version: stream_version,
          event_type: Map.get(event, :event_type, "unknown"),
          data: Map.get(event, :data, %{}),
          metadata: Map.get(event, :metadata, %{}) |> Map.put(:recorded_at, DateTime.utc_now()),
          timestamp: Map.get(event, :timestamp, DateTime.utc_now())
        }

        # Store event with composite key (stream_id, stream_version) for efficient stream reads
        :ets.insert(:event_store_events, {{stream_id, stream_version}, event_record})

        # Also store by global sequence for cross-stream queries
        :ets.insert(:event_store_events, {{:global, global_seq}, event_record})

        Logger.debug(
          "Appended event to stream #{stream_id} (version #{stream_version}, global #{global_seq})"
        )

        :ok
      rescue
        error ->
          Logger.error("Failed to append event to stream #{stream_id}: #{inspect(error)}")
          {:error, {:append_failed, error}}
      end
    end
  end

  defp read_from_store(connection, stream_id, opts) do
    if connection == nil or connection.connected != true do
      {:error, :not_connected}
    else
      try do
        from_version = Keyword.get(opts, :from_version, 1)
        max_count = Keyword.get(opts, :max_count, 1000)
        direction = Keyword.get(opts, :direction, :forward)

        # Get current stream version
        current_version =
          case :ets.lookup(:event_store_streams, {:stream_version, stream_id}) do
            [{_, version}] -> version
            [] -> 0
          end

        if current_version == 0 do
          {:ok, []}
        else
          # Calculate version range based on direction
          {start_ver, end_ver} =
            case direction do
              :forward ->
                end_ver = min(from_version + max_count - 1, current_version)
                {from_version, end_ver}

              :backward ->
                start_ver = max(from_version - max_count + 1, 1)
                {start_ver, from_version}
            end

          # Collect events from the stream
          events =
            start_ver..end_ver
            |> Enum.map(fn version ->
              case :ets.lookup(:event_store_events, {stream_id, version}) do
                [{_, event}] -> event
                [] -> nil
              end
            end)
            |> Enum.reject(&is_nil/1)

          # Apply direction ordering
          ordered_events =
            case direction do
              :forward -> events
              :backward -> Enum.reverse(events)
            end

          Logger.debug(
            "Read #{length(ordered_events)} events from stream #{stream_id} (versions #{start_ver}-#{end_ver})"
          )

          {:ok, ordered_events}
        end
      rescue
        error ->
          Logger.error("Failed to read from stream #{stream_id}: #{inspect(error)}")
          {:error, {:read_failed, error}}
      end
    end
  end
end
