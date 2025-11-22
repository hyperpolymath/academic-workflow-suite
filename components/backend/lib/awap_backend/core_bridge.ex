defmodule AwapBackend.CoreBridge do
  @moduledoc """
  Bridge to Rust core engine via NIF (Native Implemented Functions) or Port.

  Provides Elixir interface to Rust core functionality:
  - TMA parsing and processing
  - Student data anonymization
  - Feedback generation
  - Event store queries

  ## Implementation Options

  This module supports two implementation strategies:

  ### Option 1: NIF (Native Implemented Functions)
  - Fastest performance
  - Direct function calls into Rust
  - Requires careful error handling to prevent VM crashes
  - Uses Rustler library

  ### Option 2: Port Communication
  - Safer isolation
  - Slightly higher overhead
  - Better for long-running operations
  - Rust core runs as separate OS process

  The current implementation uses Port communication for safety.
  To use NIFs, implement the functions with Rustler and update the module.

  ## Configuration

      config :awap_backend, AwapBackend.CoreBridge,
        core_executable: "/path/to/rust/core/binary",
        communication_mode: :port  # or :nif

  ## Rust Core Interface

  The Rust core should accept JSON messages via stdin and respond via stdout:

      {"command": "anonymize_student", "data": {...}}
      {"command": "parse_tma", "data": {...}}
      {"command": "generate_feedback", "data": {...}}
  """

  use GenServer
  require Logger

  @type tma_data :: map()
  @type anonymized_data :: map()
  @type parsed_tma :: map()
  @type feedback :: map()

  # Client API

  @doc """
  Starts the Core Bridge GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Anonymizes student information in TMA data.

  Replaces personally identifiable information with anonymous identifiers
  to ensure blind marking.
  """
  @spec anonymize_student(tma_data()) :: {:ok, anonymized_data()} | {:error, term()}
  def anonymize_student(tma_data) do
    call_core("anonymize_student", tma_data)
  end

  @doc """
  Parses a TMA submission into structured format.

  Extracts questions, answers, metadata, and attachments.
  """
  @spec parse_tma(tma_data()) :: {:ok, parsed_tma()} | {:error, term()}
  def parse_tma(tma_data) do
    call_core("parse_tma", tma_data)
  end

  @doc """
  Generates feedback for a parsed TMA.

  Uses marking criteria and student responses to generate constructive feedback.
  """
  @spec generate_feedback(parsed_tma()) :: {:ok, feedback()} | {:error, term()}
  def generate_feedback(parsed_tma) do
    call_core("generate_feedback", parsed_tma)
  end

  @doc """
  Queries events from the event store.
  """
  @spec query_events(String.t(), keyword()) :: {:ok, list(map())} | {:error, term()}
  def query_events(stream_id, opts \\ []) do
    call_core("query_events", %{stream_id: stream_id, opts: opts})
  end

  @doc """
  Checks if the Rust core is healthy and responsive.
  """
  @spec health_check() :: :ok | {:error, term()}
  def health_check do
    case call_core("health_check", %{}) do
      {:ok, %{"status" => "healthy"}} -> :ok
      {:ok, response} -> {:error, {:unhealthy, response}}
      {:error, reason} -> {:error, reason}
    end
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    mode = get_communication_mode()

    state =
      case mode do
        :port ->
          init_port_mode()

        :nif ->
          init_nif_mode()
      end

    {:ok, state}
  end

  @impl true
  def handle_call({:call_core, command, data}, from, %{mode: :port} = state) do
    request_id = generate_request_id()

    message = %{
      request_id: request_id,
      command: command,
      data: data
    }

    json_message = Jason.encode!(message)
    Port.command(state.port, json_message <> "\n")

    # Store the caller to reply later
    pending = Map.put(state.pending_requests, request_id, from)
    {:noreply, %{state | pending_requests: pending}}
  end

  @impl true
  def handle_call({:call_core, command, data}, _from, %{mode: :nif} = state) do
    # Call Rust NIF directly
    result = call_nif(command, data)
    {:reply, result, state}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) when is_port(port) do
    case Jason.decode(data) do
      {:ok, response} ->
        request_id = Map.get(response, "request_id")
        from = Map.get(state.pending_requests, request_id)

        if from do
          result = parse_core_response(response)
          GenServer.reply(from, result)

          pending = Map.delete(state.pending_requests, request_id)
          {:noreply, %{state | pending_requests: pending}}
        else
          Logger.warn("Received response for unknown request_id: #{request_id}")
          {:noreply, state}
        end

      {:error, reason} ->
        Logger.error("Failed to decode response from Rust core: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("Rust core process exited with status #{status}")
    # Attempt to restart the port
    {:stop, {:port_exited, status}, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private Functions

  defp call_core(command, data) do
    GenServer.call(__MODULE__, {:call_core, command, data}, :infinity)
  end

  defp get_communication_mode do
    Application.get_env(:awap_backend, __MODULE__, [])
    |> Keyword.get(:communication_mode, :port)
  end

  defp init_port_mode do
    executable = get_core_executable()

    port =
      Port.open({:spawn, executable}, [
        :binary,
        :exit_status,
        {:packet, 4},
        {:args, ["--mode", "port"]}
      ])

    Logger.info("Rust core bridge started in Port mode")

    %{
      mode: :port,
      port: port,
      pending_requests: %{}
    }
  end

  defp init_nif_mode do
    # Load Rustler NIF
    # This requires Rustler to be set up in mix.exs and Rust code to be compiled
    # Example: :ok = :rustler.load_nif(:awap_core_nif)

    Logger.info("Rust core bridge started in NIF mode")

    %{
      mode: :nif
    }
  end

  defp get_core_executable do
    config = Application.get_env(:awap_backend, __MODULE__, [])

    Keyword.get(config, :core_executable, "/usr/local/bin/awap_core")
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  defp parse_core_response(%{"success" => true, "data" => data}) do
    {:ok, data}
  end

  defp parse_core_response(%{"success" => false, "error" => error}) do
    {:error, error}
  end

  defp parse_core_response(response) do
    {:error, {:invalid_response, response}}
  end

  # NIF stubs (would be implemented with Rustler)
  defp call_nif(_command, _data) do
    # This would be replaced by actual Rustler NIF implementation
    {:error, :nif_not_implemented}
  end
end
