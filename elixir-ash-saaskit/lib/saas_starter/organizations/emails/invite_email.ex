defmodule SaasStarter.Organizations.Emails.InviteEmail do
  @moduledoc """
  Email functionality for organization invitations.

  This module handles sending invitation emails when users are invited
  to join an organization. It uses the UserEmail module for the actual
  email rendering and sending.
  """

  alias SaasStarter.Emails.UserEmail
  alias SaasStarter.Mailer

  @doc """
  Sends an invitation email for a new invite.

  This function should be called after an invite is created.
  It loads the organization and sends the email.

  ## Parameters
    - invite: The invite struct with email, role, token, and organization_id
    - context: Optional context (usually from Ash actions)

  ## Returns
    - {:ok, result} on success
    - {:error, reason} on failure
  """
  def send_invite_email(invite, _context \\ %{}) do
    # Load the organization for the invite
    case load_organization(invite) do
      {:ok, organization} ->
        UserEmail.invite_email(invite, organization)
        |> Mailer.deliver()

      {:error, _reason} = error ->
        error
    end
  end

  # Private helper to load the organization
  defp load_organization(invite) do
    case SaasStarter.Organizations.Organization
         |> Ash.Query.filter(id == ^invite.organization_id)
         |> Ash.read_one(authorize?: false) do
      {:ok, nil} ->
        {:error, :organization_not_found}

      {:ok, organization} ->
        {:ok, organization}

      {:error, _reason} = error ->
        error
    end
  end
end
