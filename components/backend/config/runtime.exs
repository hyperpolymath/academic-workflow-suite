import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# Start the phoenix server if environment flag is set and running in a release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :awap_backend, AwapBackendWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :awap_backend, AwapBackend.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :awap_backend, AwapBackendWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure external services with production credentials
  config :awap_backend,
    event_store_url: System.get_env("EVENT_STORE_URL") || "tcp://localhost:1113"

  config :awap_backend, AwapBackend.Moodle,
    base_url: System.fetch_env!("MOODLE_BASE_URL"),
    client_id: System.fetch_env!("MOODLE_CLIENT_ID"),
    client_secret: System.fetch_env!("MOODLE_CLIENT_SECRET")

  config :awap_backend,
    moodle_username: System.fetch_env!("MOODLE_USERNAME"),
    moodle_password: System.fetch_env!("MOODLE_PASSWORD")

  config :awap_backend, AwapBackend.CoreBridge,
    core_executable: System.get_env("CORE_EXECUTABLE") || "/usr/local/bin/awap_core"

  config :awap_backend, AwapBackend.AI.Manager,
    container_image: System.get_env("AI_CONTAINER_IMAGE") || "localhost/awap-ai:latest",
    max_containers: String.to_integer(System.get_env("MAX_AI_CONTAINERS") || "10")
end
