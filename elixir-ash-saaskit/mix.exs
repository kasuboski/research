defmodule SaasStarter.MixProject do
  use Mix.Project

  def project do
    [
      app: :saas_starter,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
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
      mod: {SaasStarter.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      # Phoenix
      {:phoenix, "~> 1.7.19"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_dashboard, "~> 0.8"},

      # Ash Framework
      {:ash, "~> 3.10"},
      {:ash_phoenix, "~> 2.3"},
      {:ash_authentication, "~> 4.13"},
      {:ash_authentication_phoenix, "~> 2.12"},
      {:ash_postgres, "~> 2.6"},

      # Database
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18"},

      # Email
      {:swoosh, "~> 1.16"},
      {:finch, "~> 0.18"},
      {:phoenix_swoosh, "~> 1.2"},

      # Assets
      {:tailwind, "~> 0.2.3", runtime: Mix.env() == :dev},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},

      # Utilities
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},

      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Dev and Test
      {:floki, ">= 0.36.0", only: :test},
      {:phoenix_html_helpers, "~> 1.0"},
      {:faker, "~> 0.18", only: [:dev, :test]},
      {:lazy_html, ">= 0.0.0", only: :test}
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
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build"],
      "ash.setup": ["ash.setup", "ash_postgres.create", "ash.migrate"],
      "ash.reset": ["drop", "ash.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind saas_starter", "esbuild saas_starter"],
      "assets.deploy": [
        "tailwind saas_starter --minify",
        "esbuild saas_starter --minify",
        "phx.digest"
      ]
    ]
  end
end
