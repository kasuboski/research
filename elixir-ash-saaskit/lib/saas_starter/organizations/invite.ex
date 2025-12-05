defmodule SaasStarter.Organizations.Invite do
  @moduledoc """
  Invite resource representing a pending invitation to join an organization.

  Invites:
  - Are sent to an email address with a specific role
  - Have a unique, secure token for acceptance
  - Expire after 7 days by default
  - Are multi-tenanted by organization_id
  - Cannot be sent to existing members
  - Can only be created by organization owners

  When accepted, an invite is converted to a membership and then deleted.
  """
  use Ash.Resource,
    domain: SaasStarter.Organizations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias SaasStarter.Organizations.Changes.{GenerateInviteToken, SetDefaultExpiry}
  alias SaasStarter.Organizations.Checks.IsOwner

  postgres do
    table "invites"
    repo SaasStarter.Repo
  end

  #
  # MULTI-TENANCY CONFIGURATION
  #

  multitenancy do
    strategy :attribute
    attribute :organization_id
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

    attribute :token, :string do
      allow_nil? false
      public? true
    end

    attribute :role, :atom do
      constraints [one_of: [:owner, :member]]
      default :member
      allow_nil? false
      public? true
    end

    attribute :organization_id, :uuid do
      allow_nil? false
      public? true
    end

    attribute :expires_at, :utc_datetime do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  #
  # IDENTITIES
  #

  identities do
    identity :unique_token, [:token] do
      eager_check_with SaasStarter.Organizations
    end
  end

  #
  # RELATIONSHIPS
  #

  relationships do
    belongs_to :organization, SaasStarter.Organizations.Organization do
      attribute_writable? true
      public? true
    end
  end

  #
  # ACTIONS
  #

  actions do
    defaults [:read, :destroy]

    # Create a new invite
    create :create do
      accept [:email, :role, :organization_id, :expires_at]

      change GenerateInviteToken
      change SetDefaultExpiry

      # Send invitation email after creation
      change after_action(fn _changeset, invite, context ->
               # Send the invite email asynchronously
               Task.start(fn ->
                 SaasStarter.Organizations.Emails.InviteEmail.send_invite_email(invite, context)
               end)

               {:ok, invite}
             end)

      # Validate that the email is not already a member
      validate before_action(fn changeset, _context ->
        email = Ash.Changeset.get_attribute(changeset, :email)
        org_id = Ash.Changeset.get_attribute(changeset, :organization_id)

        # Check if user exists with this email
        case SaasStarter.Accounts.User
             |> Ash.Query.filter(email == ^email)
             |> Ash.read_one(authorize?: false) do
          {:ok, nil} ->
            # User doesn't exist yet, invite is valid
            changeset

          {:ok, user} ->
            # User exists, check if they're already a member
            case SaasStarter.Organizations.Membership
                 |> Ash.Query.filter(
                   user_id == ^user.id and organization_id == ^org_id
                 )
                 |> Ash.read_one(authorize?: false) do
              {:ok, nil} ->
                # Not a member, invite is valid
                changeset

              {:ok, _membership} ->
                Ash.Changeset.add_error(changeset, field: :email, message: "User is already a member of this organization")
            end

          {:error, _} ->
            changeset
        end
      end)
    end

    # Read invite by token (public access for acceptance)
    read :by_token do
      argument :token, :string do
        allow_nil? false
      end

      filter expr(token == ^arg(:token))
    end

    # Accept an invite and create membership
    update :accept do
      accept []

      argument :user_id, :uuid do
        allow_nil? false
      end

      # Validate invite is not expired
      validate before_action(fn changeset, _context ->
        invite = changeset.data

        if DateTime.compare(invite.expires_at, DateTime.utc_now()) == :lt do
          Ash.Changeset.add_error(changeset, field: :expires_at, message: "Invite has expired")
        else
          changeset
        end
      end)

      # Create membership and destroy invite
      change after_action(fn changeset, invite, _context ->
               user_id = Ash.Changeset.get_argument(changeset, :user_id)

               # Create the membership
               case SaasStarter.Organizations.Membership
                    |> Ash.Changeset.for_create(:create, %{
                      user_id: user_id,
                      organization_id: invite.organization_id,
                      role: invite.role
                    })
                    |> Ash.create(authorize?: false) do
                 {:ok, membership} ->
                   # Delete the invite
                   Ash.destroy!(invite, authorize?: false)
                   {:ok, membership}

                 {:error, error} ->
                   {:error, error}
               end
             end)
    end
  end

  #
  # VALIDATIONS
  #

  validations do
    validate match(:email, ~r/^[^\s]+@[^\s]+$/), message: "must be a valid email address"
    validate present(:email), message: "Email is required"
    validate present(:organization_id), message: "Organization is required"
  end

  #
  # POLICIES
  #

  policies do
    # Owners can read invites in their organization
    policy action_type(:read) do
      authorize_if IsOwner
    end

    # Owners can create invites
    policy action_type(:create) do
      authorize_if IsOwner
    end

    # Owners can destroy (revoke) invites
    policy action_type(:destroy) do
      authorize_if IsOwner
    end

    # Anyone with a valid token can accept an invite (special case)
    policy action(:accept) do
      authorize_if always()
    end

    # Public read by token for checking validity
    policy action(:by_token) do
      authorize_if always()
    end
  end

  #
  # CODE INTERFACE
  #

  code_interface do
    define :create, args: [:email, :role, :organization_id]
    define :by_token, args: [:token]
    define :accept, args: [:user_id]
    define :destroy
  end
end
