defmodule SaasStarter.Organizations.Checks.IsOwner do
  @moduledoc """
  Policy check that verifies the actor has the 'owner' role in the organization.

  This check is used to restrict certain actions (like inviting members, updating org settings,
  or deleting the organization) to only users with owner privileges.

  The check works in a multi-tenant context and respects the current tenant.
  """
  use Ash.Policy.Check

  @impl true
  def describe(_options) do
    "actor is an owner of the organization"
  end

  @impl true
  def match?(_actor, %{data: nil}, _opts), do: false
  def match?(_actor, %{data: []}, _opts), do: false
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{query: %{tenant: tenant}} = context, _opts) when not is_nil(tenant) do
    # Query context - check if actor has owner role in the tenant organization
    case get_actor_membership(actor, tenant) do
      nil -> false
      membership -> membership.role == :owner
    end
  end

  def match?(actor, %{changeset: %{tenant: tenant}} = context, _opts) when not is_nil(tenant) do
    # Changeset context - check if actor has owner role in the tenant organization
    case get_actor_membership(actor, tenant) do
      nil -> false
      membership -> membership.role == :owner
    end
  end

  def match?(actor, %{data: data}, opts) when is_list(data) do
    # For list operations, check each record
    Enum.all?(data, fn record ->
      match?(actor, %{data: record}, opts)
    end)
  end

  def match?(actor, %{data: %{organization_id: org_id}}, _opts) when not is_nil(org_id) do
    # Single record with organization_id - check membership
    case get_actor_membership(actor, org_id) do
      nil -> false
      membership -> membership.role == :owner
    end
  end

  def match?(actor, %{data: %{id: org_id}}, _opts) do
    # Organization resource itself - check if actor has owner membership
    case get_actor_membership(actor, org_id) do
      nil -> false
      membership -> membership.role == :owner
    end
  end

  def match?(_actor, _context, _opts), do: false

  defp get_actor_membership(actor, organization_id) do
    SaasStarter.Organizations.Membership
    |> Ash.Query.filter(user_id == ^actor.id and organization_id == ^organization_id)
    |> Ash.Query.limit(1)
    |> Ash.read!(authorize?: false)
    |> List.first()
  end
end
