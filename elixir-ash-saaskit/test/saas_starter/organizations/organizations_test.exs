defmodule SaasStarter.OrganizationsTest do
  @moduledoc """
  Tests for the Organizations domain public interface.
  """
  use SaasStarter.DataCase, async: true

  alias SaasStarter.{Accounts, Organizations}

  describe "organization lifecycle" do
    test "full flow: create org, add members, invite users, accept invites" do
      # Create users
      owner = create_user()
      member = create_user()
      invited_user = create_user(email: "invited@example.com")

      # 1. Create organization
      {:ok, org} =
        Organizations.create_organization_with_owner(%{name: "Acme Corp"}, actor: owner)

      assert org.name == "Acme Corp"
      assert org.slug == "acme-corp"

      # 2. Owner adds a member
      {:ok, membership} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert membership.role == :member

      # 3. Owner creates an invite
      {:ok, invite} =
        Organizations.create_invite(org.id, invited_user.email, :member,
          actor: owner,
          tenant: org.id
        )

      assert invite.email == invited_user.email

      # 4. Invited user accepts invite
      {:ok, new_membership} = Organizations.accept_invite(invite.token, actor: invited_user)
      assert new_membership.user_id == invited_user.id

      # 5. List all members
      {:ok, members} = Organizations.list_members(org.id, actor: owner, tenant: org.id)
      assert length(members) == 3

      # 6. Owner promotes member to owner
      {:ok, updated_membership} =
        Organizations.update_member_role(membership.id, :owner, actor: owner, tenant: org.id)

      assert updated_membership.role == :owner

      # 7. List user's organizations
      {:ok, user_orgs} = Organizations.list_user_organizations(member)
      assert length(user_orgs) == 1
      assert hd(user_orgs).id == org.id
    end
  end

  describe "multi-organization membership" do
    test "user can belong to multiple organizations" do
      user = create_user()
      other_owner = create_user()

      {:ok, org1} =
        Organizations.create_organization_with_owner(%{name: "Org 1"}, actor: user)

      {:ok, org2} =
        Organizations.create_organization_with_owner(%{name: "Org 2"}, actor: other_owner)

      # Add user to org2
      Organizations.add_member(org2.id, user.id, :member, actor: other_owner, tenant: org2.id)

      {:ok, user_orgs} = Organizations.list_user_organizations(user)
      assert length(user_orgs) == 2

      org_ids = Enum.map(user_orgs, & &1.id)
      assert org1.id in org_ids
      assert org2.id in org_ids
    end
  end

  describe "tenant isolation" do
    test "members of one org cannot see members of another org" do
      owner1 = create_user()
      owner2 = create_user()

      {:ok, org1} =
        Organizations.create_organization_with_owner(%{name: "Org 1"}, actor: owner1)

      {:ok, org2} =
        Organizations.create_organization_with_owner(%{name: "Org 2"}, actor: owner2)

      # Owner1 should not be able to list members of org2 even with the tenant set
      # This should fail authorization
      assert {:error, _} = Organizations.list_members(org2.id, actor: owner1, tenant: org2.id)
    end

    test "cannot create invite in another organization" do
      owner1 = create_user()
      owner2 = create_user()

      {:ok, org1} =
        Organizations.create_organization_with_owner(%{name: "Org 1"}, actor: owner1)

      {:ok, org2} =
        Organizations.create_organization_with_owner(%{name: "Org 2"}, actor: owner2)

      # Owner1 should not be able to create invite in org2
      assert {:error, _} =
               Organizations.create_invite(org2.id, "user@example.com", :member,
                 actor: owner1,
                 tenant: org2.id
               )
    end
  end

  describe "ownership and permissions" do
    test "last owner cannot be removed" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, [membership]} = Organizations.list_members(org.id, actor: owner, tenant: org.id)

      assert {:error, _} = Organizations.remove_member(membership.id, actor: owner, tenant: org.id)
    end

    test "organization can have multiple owners" do
      owner1 = create_user()
      owner2 = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner1)

      {:ok, _} =
        Organizations.add_member(org.id, owner2.id, :owner, actor: owner1, tenant: org.id)

      {:ok, members} = Organizations.list_members(org.id, actor: owner1, tenant: org.id)
      owners = Enum.filter(members, &(&1.role == :owner))
      assert length(owners) == 2
    end

    test "any owner can remove other owners when multiple exist" do
      owner1 = create_user()
      owner2 = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner1)

      {:ok, membership2} =
        Organizations.add_member(org.id, owner2.id, :owner, actor: owner1, tenant: org.id)

      # Owner2 should be able to remove owner1
      {:ok, [membership1 | _]} = Organizations.list_members(org.id, actor: owner2, tenant: org.id)

      assert {:ok, _} =
               Organizations.remove_member(membership1.id, actor: owner2, tenant: org.id)
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
