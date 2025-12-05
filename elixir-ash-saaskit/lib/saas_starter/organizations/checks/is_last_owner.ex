defmodule SaasStarter.Organizations.Checks.IsLastOwner do
  @moduledoc """
  Policy check that verifies if a membership is the last owner of an organization.

  This check is used to prevent removing the last owner from an organization,
  which would leave the organization without any administrators.

  Returns true if this is the last owner (preventing the action),
  false if there are other owners (allowing the action).
  """
  use Ash.Policy.Check

  @impl true
  def describe(_options) do
    "membership is the last owner in the organization"
  end

  @impl true
  def match?(_actor, %{data: nil}, _opts), do: false
  def match?(_actor, %{data: []}, _opts), do: false

  def match?(_actor, %{data: data}, opts) when is_list(data) do
    # For list operations, check each record
    Enum.any?(data, fn record ->
      match?(_actor, %{data: record}, opts)
    end)
  end

  def match?(_actor, %{data: membership}, _opts) do
    # Only check for owner role memberships
    if membership.role == :owner do
      is_last_owner?(membership)
    else
      # Non-owners can always be removed
      false
    end
  end

  def match?(_actor, %{changeset: changeset}, _opts) do
    # Check if we're destroying an owner membership
    if changeset.action_type == :destroy do
      # Get the membership being destroyed
      case Ash.Changeset.get_data(changeset) do
        %{role: :owner} = membership ->
          is_last_owner?(membership)

        _ ->
          false
      end
    else
      false
    end
  end

  def match?(_actor, _context, _opts), do: false

  defp is_last_owner?(membership) do
    organization_id = membership.organization_id

    owner_count =
      SaasStarter.Organizations.Membership
      |> Ash.Query.filter(organization_id == ^organization_id and role == :owner)
      |> Ash.read!(authorize?: false)
      |> length()

    # Return true if this is the last owner (which should prevent removal)
    owner_count <= 1
  end
end
