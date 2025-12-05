defmodule SaasStarter.Repo.Migrations.CreateOrganizationsResources do
  @moduledoc """
  Creates the Organizations domain tables: organizations, memberships, and invites.

  These tables implement the multi-tenancy and RBAC system for the application.
  """
  use Ecto.Migration

  def up do
    # Create organizations table (not tenanted - defines tenants)
    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :name, :text, null: false
      add :slug, :text, null: false
      add :billing_status, :text, null: false, default: "trialing"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])
    create index(:organizations, [:billing_status])

    # Create memberships table (tenanted by organization_id)
    create table(:memberships, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :role, :text, null: false, default: "member"
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:memberships, [:user_id, :organization_id])
    create index(:memberships, [:organization_id])
    create index(:memberships, [:user_id])
    create index(:memberships, [:role])

    # Create invites table (tenanted by organization_id)
    create table(:invites, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :email, :citext, null: false
      add :token, :text, null: false
      add :role, :text, null: false, default: "member"
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all),
        null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:invites, [:token])
    create index(:invites, [:organization_id])
    create index(:invites, [:email])
    create index(:invites, [:expires_at])
  end

  def down do
    drop table(:invites)
    drop table(:memberships)
    drop table(:organizations)
  end
end
