defmodule SaasStarter.Organizations do
  @moduledoc """
  The Organizations domain.

  This domain manages multi-tenancy, team management, and access control.
  It is responsible for:
  - Organization (tenant) creation and management
  - User memberships and role-based access control (RBAC)
  - Team invitations and onboarding
  - Tenant context management

  ## Multi-Tenancy Strategy

  This domain implements attribute-based multi-tenancy where:
  - Organizations are global (not tenanted)
  - Memberships and Invites are tenanted by organization_id
  - All operations on tenanted resources require a tenant context

  ## Roles

  - :owner - Full access to organization settings, can manage members and invites
  - :member - Standard access to organization resources
  """
  use Ash.Domain

  resources do
    resource SaasStarter.Organizations.Organization do
      define :get_organization, action: :read, args: [:id]
      define :get_organization_by_slug, action: :by_slug, args: [:slug]
      define :create_organization, action: :create
      define :update_organization, action: :update
      define :destroy_organization, action: :destroy
    end

    resource SaasStarter.Organizations.Membership do
      define :get_membership, action: :read, args: [:id]
      define :create_membership, action: :create
      define :update_membership, action: :update
      define :destroy_membership, action: :destroy
    end

    resource SaasStarter.Organizations.Invite do
      define :get_invite, action: :read, args: [:id]
      define :get_invite_by_token, action: :by_token, args: [:token]
      define :create_invite, action: :create
      define :destroy_invite, action: :destroy
    end
  end

  #
  # PUBLIC INTERFACE
  #

  @doc """
  Create an organization with the actor as the owner.

  This is an atomic operation that creates both the organization and the owner membership
  in a single transaction.

  ## Examples

      iex> create_organization_with_owner(%{name: "Acme Corp"}, actor: user)
      {:ok, %Organization{name: "Acme Corp", slug: "acme-corp"}}

  ## Options

  - :actor - The user who will be the owner (required)
  """
  def create_organization_with_owner(params, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    unless actor do
      {:error, "Actor is required to create an organization"}
    else
      params_with_user = Map.put(params, :user_id, actor.id)

      SaasStarter.Organizations.Organization
      |> Ash.Changeset.for_create(:create_with_owner, params_with_user, actor: actor)
      |> Ash.create()
    end
  end

  @doc """
  Get an organization by its slug.

  ## Examples

      iex> get_by_slug("acme-corp", actor: user)
      {:ok, %Organization{slug: "acme-corp"}}

  ## Options

  - :actor - The current user (required for authorization)
  """
  def get_by_slug(slug, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    SaasStarter.Organizations.Organization
    |> Ash.Query.for_read(:by_slug, %{slug: slug}, actor: actor)
    |> Ash.read_one()
  end

  @doc """
  List all organizations a user belongs to.

  ## Examples

      iex> list_user_organizations(user)
      {:ok, [%Organization{}, ...]}
  """
  def list_user_organizations(user) do
    # Get all memberships for the user
    case SaasStarter.Organizations.Membership
         |> Ash.Query.filter(user_id == ^user.id)
         |> Ash.Query.load(:organization)
         |> Ash.read(authorize?: false) do
      {:ok, memberships} ->
        organizations = Enum.map(memberships, & &1.organization)
        {:ok, organizations}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Add a member to an organization.

  ## Examples

      iex> add_member(org_id, user_id, :member, actor: owner, tenant: org_id)
      {:ok, %Membership{}}

  ## Options

  - :actor - The user performing the action (must be an owner)
  - :tenant - The organization_id context (required for multi-tenancy)
  """
  def add_member(org_id, user_id, role, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)

    SaasStarter.Organizations.Membership
    |> Ash.Changeset.for_create(
      :create,
      %{
        organization_id: org_id,
        user_id: user_id,
        role: role
      },
      actor: actor,
      tenant: tenant
    )
    |> Ash.create()
  end

  @doc """
  Remove a member from an organization.

  Prevents removing the last owner.

  ## Examples

      iex> remove_member(membership_id, actor: owner, tenant: org_id)
      :ok

  ## Options

  - :actor - The user performing the action (must be an owner)
  - :tenant - The organization_id context (required for multi-tenancy)
  """
  def remove_member(membership_id, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)

    case Ash.get(SaasStarter.Organizations.Membership, membership_id,
           actor: actor,
           tenant: tenant
         ) do
      {:ok, membership} ->
        membership
        |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor, tenant: tenant)
        |> Ash.destroy()

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Update a member's role.

  ## Examples

      iex> update_member_role(membership_id, :owner, actor: owner, tenant: org_id)
      {:ok, %Membership{role: :owner}}

  ## Options

  - :actor - The user performing the action (must be an owner)
  - :tenant - The organization_id context (required for multi-tenancy)
  """
  def update_member_role(membership_id, new_role, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)

    case Ash.get(SaasStarter.Organizations.Membership, membership_id,
           actor: actor,
           tenant: tenant
         ) do
      {:ok, membership} ->
        membership
        |> Ash.Changeset.for_update(:update, %{role: new_role}, actor: actor, tenant: tenant)
        |> Ash.update()

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Create an invitation to join an organization.

  ## Examples

      iex> create_invite(org_id, "user@example.com", :member, actor: owner, tenant: org_id)
      {:ok, %Invite{token: "..."}}

  ## Options

  - :actor - The user performing the action (must be an owner)
  - :tenant - The organization_id context (required for multi-tenancy)
  """
  def create_invite(org_id, email, role, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)

    SaasStarter.Organizations.Invite
    |> Ash.Changeset.for_create(
      :create,
      %{
        organization_id: org_id,
        email: email,
        role: role
      },
      actor: actor,
      tenant: tenant
    )
    |> Ash.create()
  end

  @doc """
  Accept an invitation and create a membership.

  ## Examples

      iex> accept_invite(token, actor: user)
      {:ok, %Membership{}}

  ## Options

  - :actor - The user accepting the invite (required)
  """
  def accept_invite(token, opts \\ []) do
    actor = Keyword.get(opts, :actor)

    unless actor do
      {:error, "Actor is required to accept an invite"}
    else
      # First, find the invite by token
      case SaasStarter.Organizations.Invite
           |> Ash.Query.for_read(:by_token, %{token: token})
           |> Ash.read_one(authorize?: false) do
        {:ok, nil} ->
          {:error, "Invite not found or invalid token"}

        {:ok, invite} ->
          # Accept the invite (this will create membership and destroy invite)
          invite
          |> Ash.Changeset.for_update(:accept, %{user_id: actor.id})
          |> Ash.update()

        {:error, error} ->
          {:error, error}
      end
    end
  end

  @doc """
  List all members of an organization.

  ## Examples

      iex> list_members(org_id, actor: user, tenant: org_id)
      {:ok, [%Membership{}, ...]}

  ## Options

  - :actor - The current user (required for authorization)
  - :tenant - The organization_id context (required for multi-tenancy)
  """
  def list_members(org_id, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)

    SaasStarter.Organizations.Membership
    |> Ash.Query.filter(organization_id == ^org_id)
    |> Ash.Query.load(:user)
    |> Ash.read(actor: actor, tenant: tenant)
  end

  @doc """
  List all pending invites for an organization.

  ## Examples

      iex> list_invites(org_id, actor: owner, tenant: org_id)
      {:ok, [%Invite{}, ...]}

  ## Options

  - :actor - The current user (must be an owner)
  - :tenant - The organization_id context (required for multi-tenancy)
  """
  def list_invites(org_id, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)

    SaasStarter.Organizations.Invite
    |> Ash.Query.filter(organization_id == ^org_id)
    |> Ash.read(actor: actor, tenant: tenant)
  end
end
