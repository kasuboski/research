defmodule SaasStarter.Repo.Migrations.CreateAccountsResources do
  @moduledoc """
  Migration to create tables for the Accounts domain.

  Creates:
  - users table: stores user identity and authentication data
  - tokens table: stores authentication tokens (sessions, magic links, password resets)
  """
  use Ecto.Migration

  def up do
    # Create users table
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :email, :citext, null: false
      add :hashed_password, :text
      add :full_name, :text
      add :avatar_url, :text

      timestamps(type: :utc_datetime_usec)
    end

    # Create unique index on email
    create unique_index(:users, [:email])

    # Create tokens table for AshAuthentication
    create table(:tokens, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :subject, :text, null: false
      add :token, :text, null: false
      add :purpose, :text, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :extra_data, :map

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    # Create indexes for token lookups
    create unique_index(:tokens, [:token])
    create index(:tokens, [:subject])
    create index(:tokens, [:purpose])
    create index(:tokens, [:expires_at])

    # Enable citext extension for case-insensitive email
    execute "CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext"
  end

  def down do
    drop_if_exists table(:tokens)
    drop_if_exists table(:users)
    execute "DROP EXTENSION IF EXISTS citext", "CREATE EXTENSION IF NOT EXISTS citext"
  end
end
