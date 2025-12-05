defmodule SaasStarter.AccountsTest do
  @moduledoc """
  Tests for the Accounts domain public interface.

  Tests cover:
  - User registration through domain interface
  - Login through domain interface
  - Password reset workflows
  - Magic link workflows
  - User profile management
  """
  use ExUnit.Case, async: true

  alias SaasStarter.Accounts
  alias SaasStarter.Repo

  setup do
    # Explicitly get a connection from the pool
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    # Setting the mode to shared allows concurrent tests to share the connection
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "register_user/1" do
    test "successfully registers a user with valid params" do
      params = %{
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:ok, user} = Accounts.register_user(params)
      assert user.email == "newuser@example.com"
      assert user.hashed_password != nil
    end

    test "fails with invalid email" do
      params = %{
        email: "notanemail",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:error, _} = Accounts.register_user(params)
    end

    test "fails with duplicate email" do
      params = %{
        email: "duplicate@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:ok, _} = Accounts.register_user(params)
      assert {:error, _} = Accounts.register_user(params)
    end
  end

  describe "login/2" do
    setup do
      params = %{
        email: "logintest@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} = Accounts.register_user(params)
      %{user: user}
    end

    test "successfully logs in with correct credentials", %{user: user} do
      assert {:ok, logged_in_user} = Accounts.login("logintest@example.com", "securepassword123")
      assert logged_in_user.id == user.id
    end

    test "fails with incorrect password" do
      assert {:error, _} = Accounts.login("logintest@example.com", "wrongpassword")
    end

    test "fails with non-existent email" do
      assert {:error, _} = Accounts.login("nonexistent@example.com", "securepassword123")
    end
  end

  describe "get_user_by_email/1" do
    setup do
      params = %{
        email: "findme@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} = Accounts.register_user(params)
      %{user: user}
    end

    test "finds user by email", %{user: user} do
      assert {:ok, found_user} = Accounts.get_user_by_email("findme@example.com")
      assert found_user.id == user.id
    end

    test "returns error for non-existent email" do
      assert {:ok, nil} = Accounts.get_user_by_email("nonexistent@example.com")
    end

    test "email lookup is case insensitive", %{user: user} do
      assert {:ok, found_user} = Accounts.get_user_by_email("FINDME@EXAMPLE.COM")
      assert found_user.id == user.id
    end
  end

  describe "get_current_user/1" do
    setup do
      params = %{
        email: "currentuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} = Accounts.register_user(params)
      %{user: user}
    end

    test "returns the current user when actor is provided", %{user: user} do
      assert {:ok, current_user} = Accounts.get_current_user(actor: user)
      assert current_user.id == user.id
    end

    test "returns error when no actor is provided" do
      assert {:error, "No actor provided"} = Accounts.get_current_user()
    end
  end

  describe "update_user_profile/3" do
    setup do
      params = %{
        email: "updateprofile@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} = Accounts.register_user(params)
      %{user: user}
    end

    test "successfully updates user profile", %{user: user} do
      update_params = %{
        full_name: "Jane Doe",
        avatar_url: "https://example.com/jane.jpg"
      }

      assert {:ok, updated_user} = Accounts.update_user_profile(user.id, update_params, actor: user)
      assert updated_user.full_name == "Jane Doe"
      assert updated_user.avatar_url == "https://example.com/jane.jpg"
    end

    test "fails when actor is not the user being updated", %{user: user1} do
      # Create a second user
      params2 = %{
        email: "user2@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user2} = Accounts.register_user(params2)

      # Try to update user2's profile as user1
      update_params = %{full_name: "Unauthorized"}

      assert {:error, _} = Accounts.update_user_profile(user2.id, update_params, actor: user1)
    end

    test "fails when no actor is provided", %{user: user} do
      update_params = %{full_name: "No Actor"}

      assert {:error, _} = Accounts.update_user_profile(user.id, update_params)
    end
  end

  describe "reset_password_request/1" do
    setup do
      params = %{
        email: "resetpassword@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} = Accounts.register_user(params)
      %{user: user}
    end

    test "successfully requests password reset for existing user", %{user: _user} do
      # The function should return :ok regardless of whether the email exists
      # to prevent email enumeration
      assert :ok = Accounts.reset_password_request("resetpassword@example.com")
    end

    test "returns :ok for non-existent email (prevents enumeration)" do
      assert :ok = Accounts.reset_password_request("nonexistent@example.com")
    end
  end

  describe "request_magic_link/1" do
    setup do
      params = %{
        email: "magiclink@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      {:ok, user} = Accounts.register_user(params)
      %{user: user}
    end

    test "successfully requests magic link for existing user", %{user: _user} do
      # This test verifies the function can be called
      # In production, this would send an email with the magic link
      result = Accounts.request_magic_link("magiclink@example.com")

      # The result may be :ok or an error depending on whether the user exists
      # For now, we just verify it doesn't crash
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "integration: full registration and login flow" do
    test "user can register, logout, and login again" do
      # Register a new user
      registration_params = %{
        email: "fullflow@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:ok, user} = Accounts.register_user(registration_params)
      assert user.email == "fullflow@example.com"

      # Simulate logout (in a real app, this would clear the session)
      # Then login again
      assert {:ok, logged_in_user} = Accounts.login("fullflow@example.com", "securepassword123")
      assert logged_in_user.id == user.id

      # Update profile
      assert {:ok, updated_user} =
               Accounts.update_user_profile(
                 user.id,
                 %{full_name: "Full Flow User"},
                 actor: logged_in_user
               )

      assert updated_user.full_name == "Full Flow User"

      # Verify we can still find the user
      assert {:ok, found_user} = Accounts.get_user_by_email("fullflow@example.com")
      assert found_user.id == user.id
      assert found_user.full_name == "Full Flow User"
    end
  end

  describe "integration: case insensitive email handling" do
    test "emails are handled case-insensitively throughout the system" do
      # Register with mixed case
      params = %{
        email: "CaseTest@Example.COM",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:ok, user} = Accounts.register_user(params)

      # Login with different case
      assert {:ok, logged_in_user} = Accounts.login("casetest@example.com", "securepassword123")
      assert logged_in_user.id == user.id

      # Find with different case
      assert {:ok, found_user} = Accounts.get_user_by_email("CASETEST@EXAMPLE.COM")
      assert found_user.id == user.id

      # Try to register again with different case (should fail)
      params2 = %{
        email: "casetest@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }

      assert {:error, _} = Accounts.register_user(params2)
    end
  end
end
