defmodule AwapBackendWeb.API.HealthController do
  @moduledoc """
  Health check endpoint for monitoring and load balancers.
  """

  use AwapBackendWeb, :controller

  alias AwapBackend.{Repo, CoreBridge, AI}

  @doc """
  GET /api/health

  Returns health status of all system components.
  """
  def index(conn, _params) do
    health = %{
      status: "healthy",
      timestamp: DateTime.utc_now(),
      components: %{
        database: check_database(),
        core_engine: check_core_engine(),
        ai_containers: check_ai_containers()
      }
    }

    status_code = if all_healthy?(health.components), do: :ok, else: :service_unavailable

    conn
    |> put_status(status_code)
    |> json(health)
  end

  defp check_database do
    case Repo.query("SELECT 1", []) do
      {:ok, _} -> %{status: "healthy"}
      {:error, reason} -> %{status: "unhealthy", error: inspect(reason)}
    end
  end

  defp check_core_engine do
    case CoreBridge.health_check() do
      :ok -> %{status: "healthy"}
      {:error, reason} -> %{status: "unhealthy", error: inspect(reason)}
    end
  end

  defp check_ai_containers do
    case AI.Manager.health_check() do
      %{total_containers: total} when total > 0 ->
        %{status: "healthy", containers: total}

      _ ->
        %{status: "degraded", containers: 0}
    end
  end

  defp all_healthy?(components) do
    Enum.all?(components, fn {_key, component} ->
      Map.get(component, :status) in ["healthy", "degraded"]
    end)
  end
end
