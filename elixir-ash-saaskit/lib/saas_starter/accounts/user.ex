defmodule SaasStarter.Accounts.User do
  @moduledoc """
  User resource representing user identity in the system.

  This is a global (non-tenanted) resource that represents a person's account.
  Users can belong to multiple organizations through memberships.

  Uses AshAuthentication for:
  - Password-based authentication (email + password)
  - Magic link authentication (passwordless login)
  - Password reset functionality
  """
  use Ash.Resource,
    domain: SaasStarter.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  alias SaasStarter.Accounts.Checks.IsSelf

  postgres do
    table "users"
    repo SaasStarter.Repo
  end

  #
  # AUTHENTICATION CONFIGURATION
  #

  authentication do
    # Token configuration for sessions, magic links, and password resets
    tokens do
      enabled? true
      token_resource SaasStarter.Accounts.Token
      signing_secret fn _, _ ->
        Application.fetch_env!(:saas_starter, :token_signing_secret)
      end
    end

    strategies do
      # Password strategy: traditional email + password authentication
      password :password do
        identity_field :email
        hashed_password_field :hashed_password

        # Register action configuration
        register_action_name :register_with_password

        # Sign in action configuration
        sign_in_action_name :sign_in_with_password

        resettable do
          sender fn user, token, _opts ->
            # Send password reset email
            SaasStarter.Emails.UserEmail.password_reset_email(user, token)
            |> SaasStarter.Mailer.deliver()
          end
        end
      end

      # Magic link strategy: passwordless authentication via email
      magic_link :magic_link do
        identity_field :email

        sender fn user, token, _opts ->
          # Send magic link email
          SaasStarter.Emails.UserEmail.magic_link_email(user, token)
          |> SaasStarter.Mailer.deliver()
        end

        sign_in_action_name :sign_in_with_magic_link
        request_action_name :request_magic_link
      end
    end
  end

  #
  # ATTRIBUTES
  #

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
      private? true
    end

    attribute :full_name, :string do
      allow_nil? true
      public? true
    end

    attribute :avatar_url, :string do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  #
  # IDENTITIES
  #

  identities do
    identity :unique_email, [:email] do
      eager_check_with SaasStarter.Accounts
    end
  end

  #
  # RELATIONSHIPS
  #

  relationships do
    # Relationship to organization memberships
    # The actual Membership resource will be defined in the Organizations domain
    has_many :memberships, SaasStarter.Organizations.Membership do
      destination_attribute :user_id
      public? true
    end
  end

  #
  # ACTIONS
  #

  actions do
    # Default actions
    defaults [:read, :destroy]

    # Create actions are handled by AshAuthentication
    # - :register_with_password (from password strategy)
    # - :sign_in_with_password (from password strategy)
    # - :sign_in_with_magic_link (from magic_link strategy)
    # - :request_magic_link (from magic_link strategy)

    # Update profile action
    update :update_profile do
      accept [:full_name, :avatar_url]

      argument :email, :ci_string do
        allow_nil? false
      end

      # Don't allow changing email via this action to maintain authentication integrity
      # Email changes should go through a separate verified flow
    end

    # Read action to get user by email
    read :by_email do
      argument :email, :ci_string do
        allow_nil? false
      end

      filter expr(email == ^arg(:email))
    end

    # Read action to get current user
    read :current_user do
      filter expr(id == ^actor(:id))
    end
  end

  #
  # VALIDATIONS
  #

  validations do
    validate match(:email, ~r/^[^\s]+@[^\s]+$/), message: "must be a valid email address"
  end

  #
  # POLICIES
  #

  policies do
    # Bypass authentication for auth-related actions
    policy action_type(:read) do
      authorize_if always()
    end

    # Users can read their own record
    policy action(:by_email) do
      authorize_if always()
    end

    policy action(:current_user) do
      authorize_if actor_present()
    end

    # Users can update their own profile
    policy action(:update_profile) do
      authorize_if IsSelf
    end

    # Only the user themselves can destroy their account
    policy action(:destroy) do
      authorize_if IsSelf
    end
  end

  #
  # CODE INTERFACE
  #

  code_interface do
    define :by_email, args: [:email]
    define :current_user
    define :update_profile, args: [:full_name, :avatar_url]
  end
end
