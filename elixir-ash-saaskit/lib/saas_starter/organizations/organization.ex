defmodule SaasStarter.Organizations.Organization do
  @moduledoc """
  Organization resource representing a tenant in the system.

  Organizations are the core multi-tenancy unit. Each organization:
  - Has its own set of members with roles (owner, member)
  - Can have multiple owners and members
  - Owns all tenant-specific data through the organization_id attribute
  - Has a unique URL-friendly slug for routing

  Note: Organizations themselves are NOT multi-tenanted (global? true).
  They define the tenants for other resources.
  """
  use Ash.Resource,
    domain: SaasStarter.Organizations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias SaasStarter.Organizations.Changes.GenerateSlug
  alias SaasStarter.Organizations.Checks.{IsOwner, HasMembership}

  postgres do
    table "organizations"
    repo SaasStarter.Repo
  end

  #
  # ATTRIBUTES
  #

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :billing_status, :atom do
      constraints [one_of: [:active, :trialing, :past_due, :canceled]]
      default :trialing
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
    identity :unique_slug, [:slug] do
      eager_check_with SaasStarter.Organizations
    end
  end

  #
  # RELATIONSHIPS
  #

  relationships do
    has_many :memberships, SaasStarter.Organizations.Membership do
      destination_attribute :organization_id
      public? true
    end

    has_many :invites, SaasStarter.Organizations.Invite do
      destination_attribute :organization_id
      public? true
    end

    many_to_many :users, SaasStarter.Accounts.User do
      through SaasStarter.Organizations.Membership
      source_attribute_on_join_resource :organization_id
      destination_attribute_on_join_resource :user_id
      public? true
    end
  end

  #
  # ACTIONS
  #

  actions do
    defaults [:read, :update, :destroy]

    # Standard create action
    create :create do
      accept [:name, :slug, :billing_status]

      change GenerateSlug
    end

    # Atomic action to create organization with owner membership
    create :create_with_owner do
      accept [:name, :slug, :billing_status]

      argument :user_id, :uuid do
        allow_nil? false
      end

      change GenerateSlug

      # After creating the org, create the owner membership
      change after_action(fn changeset, org, _context ->
               user_id = Ash.Changeset.get_argument(changeset, :user_id)

               case SaasStarter.Organizations.Membership
                    |> Ash.Changeset.for_create(:create, %{
                      user_id: user_id,
                      organization_id: org.id,
                      role: :owner
                    })
                    |> Ash.create() do
                 {:ok, _membership} ->
                   {:ok, org}

                 {:error, error} ->
                   {:error, error}
               end
             end)
    end

    # Read organization by slug
    read :by_slug do
      argument :slug, :string do
        allow_nil? false
      end

      filter expr(slug == ^arg(:slug))
    end
  end

  #
  # VALIDATIONS
  #

  validations do
    validate present(:name), message: "Name is required"
    validate string_length(:name, min: 2), message: "Name must be at least 2 characters"

    validate match(:slug, ~r/^[a-z0-9-]+$/),
      message: "Slug must be lowercase alphanumeric with hyphens only"
  end

  #
  # POLICIES
  #

  policies do
    # Any authenticated user can create an organization
    policy action(:create) do
      authorize_if actor_present()
    end

    policy action(:create_with_owner) do
      authorize_if actor_present()
    end

    # Anyone can read organizations by slug (we'll check membership in other resources)
    policy action(:by_slug) do
      authorize_if actor_present()
    end

    # Users can read organizations they're a member of
    policy action_type(:read) do
      authorize_if actor_present()
      authorize_if HasMembership
    end

    # Only owners can update or destroy organizations
    policy action_type([:update, :destroy]) do
      authorize_if IsOwner
    end
  end

  #
  # CODE INTERFACE
  #

  code_interface do
    define :create, args: [:name]
    define :create_with_owner, args: [:name, :user_id]
    define :by_slug, args: [:slug]
    define :update
    define :destroy
  end
end
