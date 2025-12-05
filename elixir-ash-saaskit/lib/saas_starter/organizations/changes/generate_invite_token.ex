defmodule SaasStarter.Organizations.Changes.GenerateInviteToken do
  @moduledoc """
  Change module that generates a secure random token for organization invites.

  The token is:
  - URL-safe
  - Cryptographically secure
  - 32 bytes (encoded as base64 URL-safe string)
  - Unique across all invites
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    # Only generate if token is not already set
    case Ash.Changeset.get_attribute(changeset, :token) do
      nil ->
        token = generate_token()
        Ash.Changeset.force_change_attribute(changeset, :token, token)

      _token ->
        # Token already provided, leave it as is
        changeset
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
end
