defmodule SaasStarter.Repo do
  use AshPostgres.Repo, otp_app: :saas_starter

  def installed_extensions do
    # Add extensions here, and then run `mix ash_postgres.generate_migrations` to generate migrations to install them
    # e.g. ["ash-functions", "uuid-ossp", "citext"]
    ["ash-functions", "uuid-ossp", "citext"]
  end
end
