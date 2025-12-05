defmodule SaasStarter.Accounts do
  @moduledoc """
  The Accounts domain.

  This domain manages user identity and global authentication.
  It is responsible for:
  - User registration and login
  - Password management (reset, change)
  - Magic link authentication
  - Session management via tokens
  """
  use Ash.Domain, extensions: [AshAuthentication.Domain]

  resources do
    resource SaasStarter.Accounts.User do
      define :get_user_by_email, action: :by_email, args: [:email]
      define :get_current_user, action: :current_user
      define :update_user_profile, action: :update_profile
      define :list_users, action: :read
      define :destroy_user, action: :destroy
    end

    resource SaasStarter.Accounts.Token
  end

  #
  # PUBLIC INTERFACE
  #

  @doc """
  Register a new user with email and password.

  ## Examples

      iex> register_user(%{email: "user@example.com", password: "securepassword123"})
      {:ok, %User{}}

      iex> register_user(%{email: "invalid", password: "short"})
      {:error, %Ash.Error.Invalid{}}
  """
  def register_user(params) do
    SaasStarter.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, params)
    |> Ash.create()
  end

  @doc """
  Sign in a user with email and password.

  ## Examples

      iex> login("user@example.com", "securepassword123")
      {:ok, %User{}}

      iex> login("user@example.com", "wrongpassword")
      {:error, %Ash.Error.Invalid{}}
  """
  def login(email, password) do
    SaasStarter.Accounts.User
    |> Ash.Changeset.for_create(:sign_in_with_password, %{email: email, password: password})
    |> Ash.create()
  end

  @doc """
  Request a magic link for passwordless authentication.

  ## Examples

      iex> request_magic_link("user@example.com")
      :ok
  """
  def request_magic_link(email) do
    case SaasStarter.Accounts.User
         |> Ash.Changeset.for_create(:request_magic_link, %{email: email})
         |> Ash.create() do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Sign in using a magic link token.

  ## Examples

      iex> sign_in_with_magic_link(token)
      {:ok, %User{}}
  """
  def sign_in_with_magic_link(token) do
    SaasStarter.Accounts.User
    |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token})
    |> Ash.create()
  end

  @doc """
  Request a password reset for the given email.

  ## Examples

      iex> reset_password_request("user@example.com")
      :ok
  """
  def reset_password_request(email) do
    case get_user_by_email(email) do
      {:ok, user} ->
        # AshAuthentication handles the reset token generation
        case AshAuthentication.Strategy.Password.request_password_reset(
               SaasStarter.Accounts.User,
               %{email: email}
             ) do
          :ok -> :ok
          {:error, error} -> {:error, error}
        end

      {:error, _} ->
        # Don't reveal whether the email exists or not
        :ok
    end
  end

  @doc """
  Reset password using a reset token.

  ## Examples

      iex> reset_password(token, "newsecurepassword123")
      {:ok, %User{}}
  """
  def reset_password(token, new_password) do
    case AshAuthentication.Strategy.Password.reset_password(
           SaasStarter.Accounts.User,
           %{reset_token: token, password: new_password, password_confirmation: new_password}
         ) do
      {:ok, user} -> {:ok, user}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Update a user's profile information.

  ## Examples

      iex> update_user_profile(user_id, %{full_name: "John Doe"}, actor: current_user)
      {:ok, %User{}}
  """
  def update_user_profile(user_id, params, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    case Ash.get(SaasStarter.Accounts.User, user_id, actor: actor) do
      {:ok, user} ->
        user
        |> Ash.Changeset.for_update(:update_profile, params, actor: actor)
        |> Ash.update()

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Get user by email.

  ## Examples

      iex> get_user_by_email("user@example.com")
      {:ok, %User{}}
  """
  defdelegate get_user_by_email(email), to: __MODULE__.User, as: :by_email

  @doc """
  Get the current user from the actor.

  ## Examples

      iex> get_current_user(actor: current_user)
      {:ok, %User{}}
  """
  def get_current_user(opts \\ []) do
    actor = Keyword.get(opts, :actor)

    if actor do
      Ash.read_one(SaasStarter.Accounts.User, actor: actor, action: :current_user)
    else
      {:error, "No actor provided"}
    end
  end
end
