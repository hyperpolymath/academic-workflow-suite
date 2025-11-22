# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :awap_backend,
  ecto_repos: [AwapBackend.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :awap_backend, AwapBackendWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AwapBackendWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: AwapBackend.PubSub,
  live_view: [signing_salt: "awap_live_view"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :mfa]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Core Engine Configuration
config :awap_backend,
  core_worker_pool_size: 10,
  event_store_url: System.get_env("EVENT_STORE_URL", "tcp://localhost:1113")

# Moodle Integration Configuration
config :awap_backend, AwapBackend.Moodle,
  base_url: System.get_env("MOODLE_BASE_URL", "https://moodle.example.edu"),
  client_id: System.get_env("MOODLE_CLIENT_ID"),
  client_secret: System.get_env("MOODLE_CLIENT_SECRET"),
  token_endpoint: "/oauth2/token",
  api_endpoint: "/webservice/rest/server.php"

# Moodle Sync Configuration
config :awap_backend,
  moodle_sync_interval: :timer.minutes(15),
  moodle_username: System.get_env("MOODLE_USERNAME"),
  moodle_password: System.get_env("MOODLE_PASSWORD")

# Core Bridge Configuration
config :awap_backend, AwapBackend.CoreBridge,
  core_executable: System.get_env("CORE_EXECUTABLE", "/usr/local/bin/awap_core"),
  communication_mode: :port

# AI Manager Configuration
config :awap_backend, AwapBackend.AI.Manager,
  container_image: System.get_env("AI_CONTAINER_IMAGE", "localhost/awap-ai:latest"),
  max_containers: String.to_integer(System.get_env("MAX_AI_CONTAINERS", "5")),
  max_memory: System.get_env("AI_MAX_MEMORY", "2g"),
  max_cpus: System.get_env("AI_MAX_CPUS", "1.0"),
  network_mode: System.get_env("AI_NETWORK_MODE", "none")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
