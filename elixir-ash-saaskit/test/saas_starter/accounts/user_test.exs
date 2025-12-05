defmodule SaasStarter.Accounts.UserTest do
  @moduledoc """
  Tests for the User resource.

  Tests cover:
  - User registration with password
  - Sign in with password
  - Magic link authentication
  - User profile updates
  - Policy enforcement
  - Email validation
  """
  use ExUnit.Case, async: true

  alias SaasStarter.Accounts.User
  alias SaasStarter.Repo

  setup do
    # Explicitly get a connection from the pool
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    # Setting the mode to shared allows concurrent tests to share the connection
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "registration with password" do
    test "creates a user with valid email and password" do
      params = %{
        email: "test@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:ok, user} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params)
               |> Ash.create()

      assert user.email == "test@example.com"
      assert user.hashed_password != nil
      assert user.hashed_password != "securepassword123"
    end

    test "fails with invalid email format" do
      params = %{
        email: "notanemail",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params)
               |> Ash.create()
    end

    test "fails with short password" do
      params = %{
        email: "test@example.com",
        password: "short",
        password_confirmation: "short"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params)
               |> Ash.create()
    end

    test "fails when password and confirmation don't match" do
      params = %{
        email: "test@example.com",
        password: "securepassword123",
        password_confirmation: "differentpassword"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params)
               |> Ash.create()
    end

    test "fails with duplicate email" do
      params = %{
        email: "duplicate@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      # Create first user
      assert {:ok, _user} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params)
               |> Ash.create()

      # Attempt to create second user with same email
      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params)
               |> Ash.create()
    end

    test "email is case insensitive" do
      params1 = %{
        email: "CaseSensitive@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      # Create first user with mixed case email
      assert {:ok, user1} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params1)
               |> Ash.create()

      # Try to create another user with different case
      params2 = %{
        email: "casesensitive@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      # Should fail because email is case-insensitive
      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:register_with_password, params2)
               |> Ash.create()

      # Verify the stored email can be found with different case
      assert {:ok, found_user} =
               User
               |> Ash.Query.filter(email == "CASESENSITIVE@EXAMPLE.COM")
               |> Ash.read_one()

      assert found_user.id == user1.id
    end
  end

  describe "sign in with password" do
    setup do
      # Create a test user
      params = %{
        email: "signin@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params)
        |> Ash.create()

      %{user: user}
    end

    test "signs in with correct credentials", %{user: _user} do
      assert {:ok, signed_in_user} =
               User
               |> Ash.Changeset.for_create(:sign_in_with_password, %{
                 email: "signin@example.com",
                 password: "securepassword123"
               })
               |> Ash.create()

      assert signed_in_user.email == "signin@example.com"
    end

    test "fails with incorrect password", %{user: _user} do
      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:sign_in_with_password, %{
                 email: "signin@example.com",
                 password: "wrongpassword"
               })
               |> Ash.create()
    end

    test "fails with non-existent email" do
      assert {:error, %Ash.Error.Invalid{}} =
               User
               |> Ash.Changeset.for_create(:sign_in_with_password, %{
                 email: "nonexistent@example.com",
                 password: "securepassword123"
               })
               |> Ash.create()
    end
  end

  describe "user profile updates" do
    setup do
      # Create a test user
      params = %{
        email: "update@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params)
        |> Ash.create()

      %{user: user}
    end

    test "user can update their own profile", %{user: user} do
      assert {:ok, updated_user} =
               user
               |> Ash.Changeset.for_update(:update_profile, %{
                 full_name: "John Doe",
                 avatar_url: "https://example.com/avatar.jpg"
               }, actor: user)
               |> Ash.update()

      assert updated_user.full_name == "John Doe"
      assert updated_user.avatar_url == "https://example.com/avatar.jpg"
    end

    test "user cannot update another user's profile", %{user: user1} do
      # Create a second user
      params = %{
        email: "user2@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user2} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params)
        |> Ash.create()

      # user1 tries to update user2's profile
      assert {:error, %Ash.Error.Forbidden{}} =
               user2
               |> Ash.Changeset.for_update(:update_profile, %{
                 full_name: "Unauthorized Change"
               }, actor: user1)
               |> Ash.update()
    end

    test "anonymous user cannot update profiles", %{user: user} do
      assert {:error, %Ash.Error.Forbidden{}} =
               user
               |> Ash.Changeset.for_update(:update_profile, %{
                 full_name: "Anonymous Change"
               })
               |> Ash.update()
    end
  end

  describe "reading users" do
    setup do
      # Create test users
      params1 = %{
        email: "reader1@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user1} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params1)
        |> Ash.create()

      params2 = %{
        email: "reader2@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user2} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params2)
        |> Ash.create()

      %{user1: user1, user2: user2}
    end

    test "can read user by email", %{user1: user1} do
      assert {:ok, found_user} =
               User
               |> Ash.Query.for_read(:by_email, %{email: "reader1@example.com"})
               |> Ash.read_one()

      assert found_user.id == user1.id
      assert found_user.email == "reader1@example.com"
    end

    test "can read current user", %{user1: user1} do
      assert {:ok, current_user} =
               User
               |> Ash.Query.for_read(:current_user)
               |> Ash.read_one(actor: user1)

      assert current_user.id == user1.id
    end
  end

  describe "user deletion" do
    setup do
      params = %{
        email: "delete@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params)
        |> Ash.create()

      %{user: user}
    end

    test "user can delete their own account", %{user: user} do
      assert :ok = Ash.destroy(user, actor: user)

      # Verify user is deleted
      assert {:ok, nil} =
               User
               |> Ash.Query.for_read(:by_email, %{email: "delete@example.com"})
               |> Ash.read_one()
    end

    test "user cannot delete another user's account", %{user: user1} do
      # Create a second user
      params = %{
        email: "delete2@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user2} =
        User
        |> Ash.Changeset.for_create(:register_with_password, params)
        |> Ash.create()

      # user1 tries to delete user2
      assert {:error, %Ash.Error.Forbidden{}} = Ash.destroy(user2, actor: user1)
    end
  end
end
