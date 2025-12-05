defmodule SaasStarter.Organizations.InviteTest do
  @moduledoc """
  Tests for the Invite resource.
  """
  use SaasStarter.DataCase, async: true

  alias SaasStarter.{Accounts, Organizations}

  describe "create_invite/4" do
    test "owner can create an invite" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      assert {:ok, invite} =
               Organizations.create_invite(org.id, "newuser@example.com", :member,
                 actor: owner,
                 tenant: org.id
               )

      assert invite.email == "newuser@example.com"
      assert invite.role == :member
      assert invite.organization_id == org.id
      assert invite.token != nil
      assert invite.expires_at != nil
    end

    test "auto-generates secure token" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, invite1} =
        Organizations.create_invite(org.id, "user1@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      {:ok, invite2} =
        Organizations.create_invite(org.id, "user2@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      # Tokens should be unique and non-empty
      assert invite1.token != invite2.token
      assert byte_size(invite1.token) > 20
    end

    test "sets default expiry to 7 days from now" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, invite} =
        Organizations.create_invite(org.id, "user@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      now = DateTime.utc_now()
      seven_days_later = DateTime.add(now, 7, :day)

      # Check that expires_at is approximately 7 days from now (within 1 minute tolerance)
      diff = DateTime.diff(invite.expires_at, seven_days_later, :second)
      assert abs(diff) < 60
    end

    test "member cannot create invites" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               Organizations.create_invite(org.id, "newuser@example.com", :member,
                 actor: member,
                 tenant: org.id
               )
    end

    test "prevents inviting existing members" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} =
               Organizations.create_invite(org.id, member.email, :member,
                 actor: owner,
                 tenant: org.id
               )
    end

    test "validates email format" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      assert {:error, _} =
               Organizations.create_invite(org.id, "invalid-email", :member,
                 actor: owner,
                 tenant: org.id
               )
    end
  end

  describe "accept_invite/2" do
    test "accepting invite creates membership and deletes invite" do
      owner = create_user()
      new_user = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, invite} =
        Organizations.create_invite(org.id, new_user.email, :member,
          actor: owner,
          tenant: org.id
        )

      assert {:ok, membership} = Organizations.accept_invite(invite.token, actor: new_user)
      assert membership.user_id == new_user.id
      assert membership.organization_id == org.id
      assert membership.role == :member

      # Verify invite is deleted
      assert {:ok, nil} =
               SaasStarter.Organizations.Invite
               |> Ash.Query.filter(token == ^invite.token)
               |> Ash.read_one(authorize?: false)
    end

    test "cannot accept expired invite" do
      owner = create_user()
      new_user = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      # Create invite with past expiry
      past_time = DateTime.utc_now() |> DateTime.add(-1, :day)

      {:ok, invite} =
        SaasStarter.Organizations.Invite
        |> Ash.Changeset.for_create(:create, %{
          email: new_user.email,
          role: :member,
          organization_id: org.id,
          expires_at: past_time
        })
        |> Ash.create(authorize?: false)

      assert {:error, _} = Organizations.accept_invite(invite.token, actor: new_user)
    end

    test "cannot accept invite with invalid token" do
      user = create_user()

      assert {:error, "Invite not found or invalid token"} =
               Organizations.accept_invite("invalid-token", actor: user)
    end

    test "requires actor to accept invite" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, invite} =
        Organizations.create_invite(org.id, "user@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      assert {:error, "Actor is required to accept an invite"} =
               Organizations.accept_invite(invite.token)
    end
  end

  describe "list_invites/2" do
    test "owner can list pending invites" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.create_invite(org.id, "user1@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      {:ok, _} =
        Organizations.create_invite(org.id, "user2@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      assert {:ok, invites} = Organizations.list_invites(org.id, actor: owner, tenant: org.id)
      assert length(invites) == 2
    end

    test "member cannot list invites" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      assert {:error, _} = Organizations.list_invites(org.id, actor: member, tenant: org.id)
    end
  end

  describe "revoke invite" do
    test "owner can revoke an invite" do
      owner = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, invite} =
        Organizations.create_invite(org.id, "user@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      assert {:ok, _} =
               invite
               |> Ash.Changeset.for_destroy(:destroy, %{}, actor: owner, tenant: org.id)
               |> Ash.destroy()

      # Verify invite is deleted
      {:ok, invites} = Organizations.list_invites(org.id, actor: owner, tenant: org.id)
      assert length(invites) == 0
    end

    test "member cannot revoke invites" do
      owner = create_user()
      member = create_user()
      {:ok, org} = Organizations.create_organization_with_owner(%{name: "Test"}, actor: owner)

      {:ok, _} =
        Organizations.add_member(org.id, member.id, :member, actor: owner, tenant: org.id)

      {:ok, invite} =
        Organizations.create_invite(org.id, "user@example.com", :member,
          actor: owner,
          tenant: org.id
        )

      assert {:error, _} =
               invite
               |> Ash.Changeset.for_destroy(:destroy, %{}, actor: member, tenant: org.id)
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
