import Config

# Configure your database
config :saas_starter, SaasStarter.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "saas_starter_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :saas_starter, SaasStarterWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_secret_key_base_at_least_64_bytes_long_change_in_production",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:saas_starter, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:saas_starter, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :saas_starter, SaasStarterWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/saas_starter_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :saas_starter, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure swoosh for local development (mailbox preview)
config :swoosh, :api_client, Swoosh.ApiClient.Finch

# Disable Swoosh API Client as we're using the local adapter
config :saas_starter, SaasStarter.Mailer, adapter: Swoosh.Adapters.Local

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true

# Token signing secret for AshAuthentication (development only - change in production)
config :saas_starter, :token_signing_secret, "development_token_signing_secret_at_least_64_bytes_change_in_production"
