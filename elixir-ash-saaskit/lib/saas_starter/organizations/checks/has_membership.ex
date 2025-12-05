defmodule SaasStarter.Organizations.Checks.HasMembership do
  @moduledoc """
  Policy check that verifies the actor has a membership in the organization.

  This check is used to ensure users can only access organizations they belong to,
  regardless of their role (owner or member).

  The check works in a multi-tenant context and respects the current tenant.
  """
  use Ash.Policy.Check

  @impl true
  def describe(_options) do
    "actor has a membership in the organization"
  end

  @impl true
  def match?(_actor, %{data: nil}, _opts), do: false
  def match?(_actor, %{data: []}, _opts), do: false
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{query: %{tenant: tenant}} = context, _opts) when not is_nil(tenant) do
    # Query context - check if actor has any membership in the tenant organization
    has_membership?(actor, tenant)
  end

  def match?(actor, %{changeset: %{tenant: tenant}} = context, _opts) when not is_nil(tenant) do
    # Changeset context - check if actor has any membership in the tenant organization
    has_membership?(actor, tenant)
  end

  def match?(actor, %{data: data}, opts) when is_list(data) do
    # For list operations, check each record
    Enum.all?(data, fn record ->
      match?(actor, %{data: record}, opts)
    end)
  end

  def match?(actor, %{data: %{organization_id: org_id}}, _opts) when not is_nil(org_id) do
    # Single record with organization_id - check membership
    has_membership?(actor, org_id)
  end

  def match?(actor, %{data: %{id: org_id}}, _opts) do
    # Organization resource itself - check if actor has membership
    has_membership?(actor, org_id)
  end

  def match?(_actor, _context, _opts), do: false

  defp has_membership?(actor, organization_id) do
    SaasStarter.Organizations.Membership
    |> Ash.Query.filter(user_id == ^actor.id and organization_id == ^organization_id)
    |> Ash.Query.limit(1)
    |> Ash.read!(authorize?: false)
    |> case do
      [] -> false
      [_membership] -> true
    end
  end
end
