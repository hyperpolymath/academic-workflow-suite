defmodule AwapBackend.Moodle.HTTPClient do
  @moduledoc """
  HTTP client for Moodle API requests.

  Wraps an HTTP library (HTTPoison, Tesla, Req, etc.) to provide
  a consistent interface for Moodle API calls.

  In production, this would use a proper HTTP client library.
  This stub provides the interface that the Moodle module expects.
  """

  require Logger

  @doc """
  Performs a GET request with query parameters.
  """
  @spec get(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get(url, params) do
    Logger.debug("GET #{url} with params: #{inspect(params)}")

    # TODO: Replace with actual HTTP client (HTTPoison, Tesla, Req, etc.)
    # Example with HTTPoison:
    # query_string = URI.encode_query(params)
    # full_url = "#{url}?#{query_string}"
    # case HTTPoison.get(full_url) do
    #   {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
    #     {:ok, %{status: 200, body: Jason.decode!(body)}}
    #   {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
    #     {:ok, %{status: status, body: body}}
    #   {:error, %HTTPoison.Error{reason: reason}} ->
    #     {:error, reason}
    # end

    # Stub response
    {:ok, %{status: 200, body: %{}}}
  end

  @doc """
  Performs a POST request with a JSON body.
  """
  @spec post(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def post(url, body) do
    Logger.debug("POST #{url} with body: #{inspect(body)}")

    # TODO: Replace with actual HTTP client
    # Example with HTTPoison:
    # headers = [{"Content-Type", "application/json"}]
    # json_body = Jason.encode!(body)
    # case HTTPoison.post(url, json_body, headers) do
    #   {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
    #     {:ok, %{status: 200, body: Jason.decode!(response_body)}}
    #   {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
    #     {:ok, %{status: status, body: response_body}}
    #   {:error, %HTTPoison.Error{reason: reason}} ->
    #     {:error, reason}
    # end

    # Stub response
    {:ok, %{status: 200, body: %{"access_token" => "stub_token"}}}
  end
end
