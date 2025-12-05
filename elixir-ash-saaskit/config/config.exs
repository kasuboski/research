import Config

# Configure the app namespace
config :saas_starter,
  namespace: SaasStarter,
  ecto_repos: [SaasStarter.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [SaasStarter.Accounts, SaasStarter.Organizations]

# Configures the endpoint
config :saas_starter, SaasStarterWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SaasStarterWeb.ErrorHTML, json: SaasStarterWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SaasStarter.PubSub,
  live_view: [signing_salt: "saas_starter_secret"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  saas_starter: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  saas_starter: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Ash
config :ash, :disable_async?, true
config :ash, :use_all_identities_in_manage_relationship?, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
