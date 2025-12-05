defmodule SaasStarter.Organizations.OrganizationTest do
  @moduledoc """
  Tests for the Organization resource.
  """
  use SaasStarter.DataCase, async: true

  alias SaasStarter.{Accounts, Organizations}

  describe "create_organization_with_owner/2" do
    test "creates an organization with the actor as owner" do
      user = create_user()

      assert {:ok, org} =
               Organizations.create_organization_with_owner(
                 %{name: "Test Org"},
                 actor: user
               )

      assert org.name == "Test Org"
      assert org.slug == "test-org"
      assert org.billing_status == :trialing

      # Verify owner membership was created
      {:ok, memberships} = Organizations.list_members(org.id, actor: user, tenant: org.id)
      assert length(memberships) == 1
      assert hd(memberships).role == :owner
      assert hd(memberships).user_id == user.id
    end

    test "auto-generates slug from name" do
      user = create_user()

      assert {:ok, org} =
               Organizations.create_organization_with_owner(
                 %{name: "My Company!"},
                 actor: user
               )

      assert org.slug == "my-company"
    end

    test "requires unique slug" do
      user = create_user()

      {:ok, _org1} =
        Organizations.create_organization_with_owner(%{name: "Test"}, actor: user)

      assert {:error, _} =
               Organizations.create_organization_with_owner(%{name: "Test"}, actor: user)
    end

    test "requires an actor" do
      assert {:error, "Actor is required to create an organization"} =
               Organizations.create_organization_with_owner(%{name: "Test"})
    end
  end

  describe "get_by_slug/2" do
    test "finds organization by slug" do
      user = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: user)

      assert {:ok, found_org} = Organizations.get_by_slug("test", actor: user)
      assert found_org.id == org.id
    end

    test "returns error for non-existent slug" do
      user = create_user()

      assert {:ok, nil} = Organizations.get_by_slug("nonexistent", actor: user)
    end
  end

  describe "list_user_organizations/1" do
    test "returns all organizations a user belongs to" do
      user = create_user()

      {:ok, org1} = Organizations.create_organization_with_owner(%{name: "Org 1"}, actor: user)
      {:ok, org2} = Organizations.create_organization_with_owner(%{name: "Org 2"}, actor: user)

      assert {:ok, orgs} = Organizations.list_user_organizations(user)
      assert length(orgs) == 2
      assert org1.id in Enum.map(orgs, & &1.id)
      assert org2.id in Enum.map(orgs, & &1.id)
    end

    test "returns empty list for user with no organizations" do
      user = create_user()

      assert {:ok, []} = Organizations.list_user_organizations(user)
    end
  end

  describe "update organization" do
    test "owner can update organization details" do
      user = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Old Name"}, actor: user)

      assert {:ok, updated_org} =
               org
               |> Ash.Changeset.for_update(:update, %{name: "New Name"}, actor: user)
               |> Ash.update()

      assert updated_org.name == "New Name"
    end

    test "non-owner cannot update organization" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      # Add member to org
      Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      # Member should not be able to update
      assert {:error, _} =
               org
               |> Ash.Changeset.for_update(:update, %{name: "New Name"}, actor: member)
               |> Ash.update()
    end
  end

  describe "destroy organization" do
    test "owner can destroy organization" do
      user = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: user)

      assert :ok =
               org
               |> Ash.Changeset.for_destroy(:destroy, %{}, actor: user)
               |> Ash.destroy()
               |> case do
                 {:ok, _} -> :ok
                 :ok -> :ok
                 error -> error
               end
    end

    test "non-owner cannot destroy organization" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               org
               |> Ash.Changeset.for_destroy(:destroy, %{}, actor: member)
               |> Ash.destroy()
    end
  end

  # Helper functions

  defp create_user(attrs \\ %{}) do
    email = attrs[:email] || "user#{System.unique_integer()}@example.com"
    password = attrs[:password] || "password123"

    {:ok, user} = Accounts.register_user(%{email: email, password: password})
    user
  end
end
