defmodule AwapBackend.AI.Container do
  @moduledoc """
  Individual AI container management using Podman.

  Wraps Podman CLI commands to:
  - Start containers with security constraints
  - Execute feedback generation requests
  - Monitor container health
  - Clean up containers

  ## Podman Commands

  Start container:
      podman run -d \
        --name awap-ai-{id} \
        --network none \
        --memory 2g \
        --cpus 1.0 \
        --read-only \
        --tmpfs /tmp \
        --security-opt no-new-privileges \
        localhost/awap-ai:latest

  Execute command:
      podman exec awap-ai-{id} /app/generate-feedback < request.json

  Stop container:
      podman stop -t 10 awap-ai-{id}
      podman rm awap-ai-{id}
  """

  require Logger

  @type container_id :: String.t()
  @type feedback_request :: map()

  @doc """
  Starts a new AI container.

  Returns the container ID on success.
  """
  @spec start() :: {:ok, container_id()} | {:error, term()}
  def start do
    container_name = generate_container_name()
    config = get_container_config()

    args = [
      "run",
      "-d",
      "--name",
      container_name,
      "--network",
      config.network_mode,
      "--memory",
      config.max_memory,
      "--cpus",
      config.max_cpus,
      "--read-only",
      "--tmpfs",
      "/tmp",
      "--security-opt",
      "no-new-privileges",
      config.image
    ]

    case System.cmd("podman", args, stderr_to_stdout: true) do
      {output, 0} ->
        container_id = String.trim(output)
        Logger.info("Started container #{container_name} (#{container_id})")
        {:ok, container_id}

      {output, exit_code} ->
        Logger.error("Failed to start container: #{output}")
        {:error, {:podman_error, exit_code, output}}
    end
  rescue
    e ->
      Logger.error("Exception starting container: #{inspect(e)}")
      {:error, {:exception, e}}
  end

  @doc """
  Stops and removes a container.
  """
  @spec stop(container_id()) :: :ok | {:error, term()}
  def stop(container_id) do
    # Stop container with timeout
    case System.cmd("podman", ["stop", "-t", "10", container_id], stderr_to_stdout: true) do
      {_output, 0} ->
        # Remove container
        case System.cmd("podman", ["rm", container_id], stderr_to_stdout: true) do
          {_output, 0} ->
            Logger.info("Stopped and removed container #{container_id}")
            :ok

          {output, exit_code} ->
            Logger.error("Failed to remove container #{container_id}: #{output}")
            {:error, {:podman_error, exit_code, output}}
        end

      {output, exit_code} ->
        Logger.error("Failed to stop container #{container_id}: #{output}")
        {:error, {:podman_error, exit_code, output}}
    end
  rescue
    e ->
      Logger.error("Exception stopping container: #{inspect(e)}")
      {:error, {:exception, e}}
  end

  @doc """
  Processes a feedback generation request in the container.

  Sends the request as JSON to the container and receives the response.
  """
  @spec process_feedback(container_id(), feedback_request()) ::
          {:ok, map()} | {:error, term()}
  def process_feedback(container_id, request) do
    json_request = Jason.encode!(request)

    args = [
      "exec",
      "-i",
      container_id,
      "/app/generate-feedback"
    ]

    case System.cmd("podman", args, input: json_request, stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, response} ->
            Logger.debug("Container #{container_id} processed request successfully")
            {:ok, response}

          {:error, reason} ->
            Logger.error("Failed to decode container response: #{inspect(reason)}")
            {:error, {:json_decode_error, reason, output}}
        end

      {output, exit_code} ->
        Logger.error("Container execution failed: #{output}")
        {:error, {:execution_failed, exit_code, output}}
    end
  rescue
    e ->
      Logger.error("Exception processing feedback: #{inspect(e)}")
      {:error, {:exception, e}}
  end

  @doc """
  Checks container health.

  Returns `:ok` if healthy, `{:error, reason}` otherwise.
  """
  @spec health_check(container_id()) :: :ok | {:error, term()}
  def health_check(container_id) do
    args = ["inspect", container_id, "--format", "{{.State.Status}}"]

    case System.cmd("podman", args, stderr_to_stdout: true) do
      {output, 0} ->
        status = String.trim(output)

        if status == "running" do
          :ok
        else
          {:error, {:unhealthy, status}}
        end

      {output, exit_code} ->
        {:error, {:inspect_failed, exit_code, output}}
    end
  rescue
    e ->
      {:error, {:exception, e}}
  end

  @doc """
  Lists all AWAP AI containers.
  """
  @spec list() :: {:ok, list(map())} | {:error, term()}
  def list do
    args = [
      "ps",
      "-a",
      "--filter",
      "name=awap-ai-",
      "--format",
      "{{.ID}}\t{{.Names}}\t{{.Status}}"
    ]

    case System.cmd("podman", args, stderr_to_stdout: true) do
      {output, 0} ->
        containers =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(&parse_container_line/1)

        {:ok, containers}

      {output, exit_code} ->
        {:error, {:podman_error, exit_code, output}}
    end
  rescue
    e ->
      {:error, {:exception, e}}
  end

  # Private Functions

  defp generate_container_name do
    timestamp = System.system_time(:millisecond)
    random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    "awap-ai-#{timestamp}-#{random}"
  end

  defp get_container_config do
    config = Application.get_env(:awap_backend, AwapBackend.AI.Manager, [])

    %{
      image: Keyword.get(config, :container_image, "localhost/awap-ai:latest"),
      max_memory: Keyword.get(config, :max_memory, "2g"),
      max_cpus: Keyword.get(config, :max_cpus, "1.0"),
      network_mode: Keyword.get(config, :network_mode, "none")
    }
  end

  defp parse_container_line(line) do
    case String.split(line, "\t") do
      [id, name, status] ->
        %{id: id, name: name, status: status}

      _ ->
        %{id: nil, name: nil, status: nil}
    end
  end
end
