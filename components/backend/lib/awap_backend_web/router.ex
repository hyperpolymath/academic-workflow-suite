defmodule AwapBackendWeb.Router do
  @moduledoc """
  Phoenix router for the AWAP backend API.

  Defines all HTTP routes for the application.
  """

  use AwapBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AwapBackendWeb.API do
    pipe_through :api

    # TMA endpoints
    resources "/tmas", TMAController, only: [:create, :show, :index]

    # Feedback endpoint
    get "/feedback/:tma_id", TMAController, :get_feedback

    # Health check
    get "/health", HealthController, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:awap_backend, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: AwapBackendWeb.Telemetry
    end
  end
end
