defmodule AwapBackend.Moodle.HTTPClient do
  @moduledoc """
  HTTP client for Moodle API requests.

  Uses Finch for HTTP operations, providing connection pooling,
  HTTP/2 support, and efficient request handling.

  ## Configuration

  Ensure Finch is started in your application supervision tree:

      # In application.ex
      children = [
        {Finch, name: AwapBackend.Finch}
      ]

  Configure timeouts and pool settings:

      config :awap_backend, AwapBackend.Moodle.HTTPClient,
        receive_timeout: 30_000,
        pool_size: 10
  """

  require Logger

  @finch_name AwapBackend.Finch
  @default_receive_timeout 30_000

  @doc """
  Performs a GET request with query parameters.

  ## Parameters

    * `url` - The base URL for the request
    * `params` - Map of query parameters to append to the URL

  ## Returns

    * `{:ok, %{status: integer, body: term}}` - Successful response with parsed JSON body
    * `{:error, reason}` - Request or parsing failure
  """
  @spec get(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get(url, params) do
    query_string = URI.encode_query(flatten_params(params))
    full_url = "#{url}?#{query_string}"

    Logger.debug("GET #{full_url}")

    request = Finch.build(:get, full_url, headers())

    case execute_request(request) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        parse_response(status, body)

      {:error, %Mint.TransportError{reason: reason}} ->
        Logger.error("Transport error during GET request: #{inspect(reason)}")
        {:error, {:transport_error, reason}}

      {:error, reason} ->
        Logger.error("GET request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Performs a POST request with a JSON body.

  ## Parameters

    * `url` - The URL for the request
    * `body` - Map to be JSON-encoded as the request body

  ## Returns

    * `{:ok, %{status: integer, body: term}}` - Successful response with parsed JSON body
    * `{:error, reason}` - Request or parsing failure
  """
  @spec post(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def post(url, body) do
    Logger.debug("POST #{url}")

    json_body = Jason.encode!(body)

    request =
      Finch.build(
        :post,
        url,
        headers() ++ [{"content-type", "application/json"}],
        json_body
      )

    case execute_request(request) do
      {:ok, %Finch.Response{status: status, body: response_body}} ->
        parse_response(status, response_body)

      {:error, %Mint.TransportError{reason: reason}} ->
        Logger.error("Transport error during POST request: #{inspect(reason)}")
        {:error, {:transport_error, reason}}

      {:error, reason} ->
        Logger.error("POST request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Performs a POST request with form-encoded body.

  Used for OAuth2 token requests and other form submissions.
  """
  @spec post_form(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def post_form(url, params) do
    Logger.debug("POST (form) #{url}")

    form_body = URI.encode_query(flatten_params(params))

    request =
      Finch.build(
        :post,
        url,
        headers() ++ [{"content-type", "application/x-www-form-urlencoded"}],
        form_body
      )

    case execute_request(request) do
      {:ok, %Finch.Response{status: status, body: response_body}} ->
        parse_response(status, response_body)

      {:error, reason} ->
        Logger.error("POST form request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Downloads a file from the given URL.

  ## Parameters

    * `url` - The URL to download from
    * `destination` - File path to save the downloaded content

  ## Returns

    * `:ok` - File downloaded successfully
    * `{:error, reason}` - Download or file write failure
  """
  @spec download_file(String.t(), String.t()) :: :ok | {:error, term()}
  def download_file(url, destination) do
    Logger.debug("Downloading file from #{url} to #{destination}")

    request = Finch.build(:get, url, headers())

    case execute_request(request) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case File.write(destination, body) do
          :ok ->
            Logger.debug("Downloaded #{byte_size(body)} bytes to #{destination}")
            :ok

          {:error, reason} ->
            Logger.error("Failed to write downloaded file: #{inspect(reason)}")
            {:error, {:file_write_error, reason}}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp execute_request(request) do
    timeout = get_config(:receive_timeout, @default_receive_timeout)

    Finch.request(request, @finch_name, receive_timeout: timeout)
  end

  defp parse_response(status, body) when is_binary(body) do
    parsed_body =
      case Jason.decode(body) do
        {:ok, decoded} -> decoded
        {:error, _} -> body
      end

    {:ok, %{status: status, body: parsed_body}}
  end

  defp headers do
    [
      {"accept", "application/json"},
      {"user-agent", "AWAP-Backend/#{Application.spec(:awap_backend, :vsn) || "0.1.0"}"}
    ]
  end

  defp flatten_params(params) when is_map(params) do
    params
    |> Enum.flat_map(&flatten_param/1)
  end

  defp flatten_param({key, values}) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      {"#{key}[#{index}]", to_string(value)}
    end)
  end

  defp flatten_param({key, value}) when is_map(value) do
    value
    |> Enum.map(fn {sub_key, sub_value} ->
      {"#{key}[#{sub_key}]", to_string(sub_value)}
    end)
  end

  defp flatten_param({key, value}) do
    [{to_string(key), to_string(value)}]
  end

  defp get_config(key, default) do
    Application.get_env(:awap_backend, __MODULE__, [])
    |> Keyword.get(key, default)
  end
end
