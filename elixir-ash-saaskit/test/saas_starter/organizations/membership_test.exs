defmodule SaasStarter.Organizations.MembershipTest do
  @moduledoc """
  Tests for the Membership resource.
  """
  use SaasStarter.DataCase, async: true

  alias SaasStarter.{Accounts, Organizations}

  describe "add_member/4" do
    test "owner can add a new member" do
      owner = create_user()
      new_member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      assert {:ok, membership} =
               Organizations.add_member(org.id, new_member.id, :member,
                 actor: owner,
                 tenant: org.id
               )

      assert membership.organization_id == org.id
      assert membership.user_id == new_member.id
      assert membership.role == :member
    end

    test "owner can add another owner" do
      owner = create_user()
      new_owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      assert {:ok, membership} =
               Organizations.add_member(org.id, new_owner.id, :owner,
                 actor: owner,
                 tenant: org.id
               )

      assert membership.role == :owner
    end

    test "member cannot add other members" do
      owner = create_user()
      member = create_user()
      new_member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               Organizations.add_member(org.id, new_member.id, :member,
                 actor: member,
                 tenant: org.id
               )
    end

    test "prevents duplicate memberships" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               Organizations.add_member(org.id, member.id, :member,
                 actor: owner,
                 tenant: org.id
               )
    end
  end

  describe "update_member_role/3" do
    test "owner can update member role to owner" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, membership} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:ok, updated} =
               Organizations.update_member_role(membership.id, :owner,
                 actor: owner,
                 tenant: org.id
               )

      assert updated.role == :owner
    end

    test "owner can demote another owner to member" do
      owner1 = create_user()
      owner2 = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner1)

      {:ok, membership} =
        Organizations.add_member(org.id, owner2.id, :owner, actor: owner1, tenant: org.id)

      assert {:ok, updated} =
               Organizations.update_member_role(membership.id, :member,
                 actor: owner1,
                 tenant: org.id
               )

      assert updated.role == :member
    end

    test "member cannot update roles" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, membership} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               Organizations.update_member_role(membership.id, :owner,
                 actor: member,
                 tenant: org.id
               )
    end
  end

  describe "remove_member/2" do
    test "owner can remove a member" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, membership} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:ok, _} = Organizations.remove_member(membership.id, actor: owner, tenant: org.id)

      # Verify member is removed
      {:ok, members} = Organizations.list_members(org.id, actor: owner, tenant: org.id)
      assert length(members) == 1
      assert hd(members).user_id == owner.id
    end

    test "cannot remove the last owner" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      # Get the owner membership
      {:ok, [membership]} = Organizations.list_members(org.id, actor: owner, tenant: org.id)

      assert {:error, _} = Organizations.remove_member(membership.id, actor: owner, tenant: org.id)
    end

    test "can remove an owner if there are other owners" do
      owner1 = create_user()
      owner2 = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner1)

      {:ok, membership2} =
        Organizations.add_member(org.id, owner2.id, :owner, actor: owner1, tenant: org.id)

      assert {:ok, _} = Organizations.remove_member(membership2.id, actor: owner1, tenant: org.id)

      # Verify there's still one owner
      {:ok, members} = Organizations.list_members(org.id, actor: owner1, tenant: org.id)
      assert length(members) == 1
      assert hd(members).role == :owner
    end

    test "member cannot remove other members" do
      owner = create_user()
      member1 = create_user()
      member2 = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member1.id, :member, actor: owner, tenant: org.id)

      {:ok, membership2} =
        Organizations.add_member(org.id, member2.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               Organizations.remove_member(membership2.id, actor: member1, tenant: org.id)
    end
  end

  describe "list_members/2" do
    test "returns all members of an organization" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:ok, members} = Organizations.list_members(org.id, actor: owner, tenant: org.id)
      assert length(members) == 2
    end

    test "member can list members" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:ok, members} = Organizations.list_members(org.id, actor: member, tenant: org.id)
      assert length(members) == 2
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
