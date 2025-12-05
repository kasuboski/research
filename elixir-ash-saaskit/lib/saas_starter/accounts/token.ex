defmodule SaasStarter.Accounts.Token do
  @moduledoc """
  Token resource for AshAuthentication.

  This resource stores authentication tokens including:
  - Session tokens for logged-in users
  - Magic link tokens for passwordless authentication
  - Password reset tokens

  Managed automatically by AshAuthentication - no direct user access needed.
  """
  use Ash.Resource,
    domain: SaasStarter.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table "tokens"
    repo SaasStarter.Repo
  end

  # The TokenResource extension automatically defines these attributes:
  # - subject (string, required) - The token subject (usually user_id)
  # - token (string, required) - The actual token value
  # - purpose (string, required) - What the token is for (session, reset, magic_link)
  # - expires_at (utc_datetime, required) - When the token expires

  policies do
    # Tokens should only be managed by the authentication system
    # No direct user access
    policy always() do
      forbid_if always()
    end
  end
end
