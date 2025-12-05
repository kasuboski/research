defmodule SaasStarter.Organizations.Changes.SetDefaultExpiry do
  @moduledoc """
  Change module that sets the default expiration time for invites.

  Sets expires_at to 7 days from now if not explicitly provided.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    # Only set if expires_at is not already set
    case Ash.Changeset.get_attribute(changeset, :expires_at) do
      nil ->
        expires_at = DateTime.utc_now() |> DateTime.add(7, :day)
        Ash.Changeset.force_change_attribute(changeset, :expires_at, expires_at)

      _expires_at ->
        # Expiry already provided, leave it as is
        changeset
    end
  end
end
