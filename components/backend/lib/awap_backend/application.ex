defmodule AwapBackend.Application do
  @moduledoc """
  The Academic Workflow Automation Platform (AWAP) Backend Application.

  This application supervises:
  - Phoenix Endpoint for HTTP API
  - Ecto Repository for database access
  - Core Engine Worker Pool for TMA processing
  - AI Jail Manager for Podman container lifecycle
  - Moodle Sync Scheduler for periodic synchronization
  - Event Store Connection for event sourcing
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AwapBackendWeb.Telemetry,

      # Start the Ecto repository
      AwapBackend.Repo,

      # Start the PubSub system
      {Phoenix.PubSub, name: AwapBackend.PubSub},

      # Start the Endpoint (http/https)
      AwapBackendWeb.Endpoint,

      # Start the Event Store connection
      {AwapBackend.EventStore, []},

      # Start the Core Engine Worker Pool
      {AwapBackend.CoreEngine.WorkerPool, pool_size: worker_pool_size()},

      # Start the AI Jail Manager
      {AwapBackend.AI.Manager, []},

      # Start the Moodle Sync Scheduler
      {AwapBackend.Moodle.SyncScheduler, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AwapBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AwapBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp worker_pool_size do
    Application.get_env(:awap_backend, :core_worker_pool_size, 10)
  end
end
