defmodule SaasStarter.Organizations.Membership do
  @moduledoc """
  Membership resource representing the RBAC link between Users and Organizations.

  Memberships:
  - Link a user to an organization with a specific role
  - Are multi-tenanted by organization_id
  - Support two roles: :owner and :member
  - Must have at least one owner per organization
  - Prevent removing the last owner

  Multi-tenancy ensures that membership operations are scoped to a specific organization.
  """
  use Ash.Resource,
    domain: SaasStarter.Organizations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias SaasStarter.Organizations.Checks.{IsOwner, IsLastOwner}

  postgres do
    table "memberships"
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

    attribute :user_id, :uuid do
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
    identity :unique_user_per_organization, [:user_id, :organization_id] do
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

    belongs_to :user, SaasStarter.Accounts.User do
      attribute_writable? true
      public? true
    end
  end

  #
  # ACTIONS
  #

  actions do
    defaults [:read]

    # Create a new membership
    create :create do
      accept [:user_id, :organization_id, :role]
    end

    # Update membership role
    update :update do
      accept [:role]
    end

    # Remove a member from organization
    destroy :destroy do
      # Prevent destroying if this is the last owner
    end
  end

  #
  # VALIDATIONS
  #

  validations do
    # Ensure role is valid
    validate present(:role), message: "Role is required"
    validate present(:user_id), message: "User is required"
    validate present(:organization_id), message: "Organization is required"
  end

  #
  # POLICIES
  #

  policies do
    # Users in the organization can read memberships (tenant context required)
    policy action_type(:read) do
      authorize_if actor_present()
    end

    # Only owners can create new memberships
    policy action_type(:create) do
      authorize_if IsOwner
    end

    # Only owners can update membership roles
    policy action_type(:update) do
      authorize_if IsOwner
    end

    # Only owners can remove members, and cannot remove the last owner
    policy action_type(:destroy) do
      authorize_if IsOwner
      forbid_if IsLastOwner
    end
  end

  #
  # CODE INTERFACE
  #

  code_interface do
    define :create, args: [:user_id, :organization_id, :role]
    define :update
    define :destroy
  end
end
