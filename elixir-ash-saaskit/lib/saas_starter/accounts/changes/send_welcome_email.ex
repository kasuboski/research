defmodule SaasStarter.Accounts.Changes.SendWelcomeEmail do
  @moduledoc """
  Ash change that sends a welcome email after user registration.

  This change is automatically triggered after a user successfully
  registers with the system.
  """

  use Ash.Resource.Change

  @doc """
  Sends a welcome email to the newly registered user.

  This is executed asynchronously to avoid blocking the registration process.
  """
  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, user ->
      # Send welcome email asynchronously
      Task.start(fn ->
        SaasStarter.Emails.UserEmail.welcome_email(user)
        |> SaasStarter.Mailer.deliver()
      end)

      {:ok, user}
    end)
  end
end
