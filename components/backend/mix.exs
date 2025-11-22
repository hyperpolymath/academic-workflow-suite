defmodule AwapBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :awap_backend,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AwapBackend.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Phoenix and Web
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # HTTP Clients (for Moodle integration)
      # Uncomment the one you prefer:
      # {:httpoison, "~> 2.0"},
      # {:tesla, "~> 1.7"},
      # {:req, "~> 0.4"},

      # Rust NIF support (optional, for CoreBridge NIF mode)
      # Uncomment if using Rustler:
      # {:rustler, "~> 0.30"},

      # Background Jobs (optional)
      # {:oban, "~> 2.15"},

      # Development and Test
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:gettext, "~> 0.20"},

      # Testing
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.0", only: :test},

      # Code Quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
