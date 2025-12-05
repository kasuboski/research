defmodule SaasStarterWeb.Plugs.RequireOrganization do
  @moduledoc """
  Plug to redirect users without any organizations to the onboarding flow.

  This plug:
  - Checks if the current user has at least one organization membership
  - If no memberships exist, redirects to /onboarding/create-organization
  - Allows the request to continue if user has memberships

  Should be used on authenticated routes that require organization access.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias SaasStarter.Organizations

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if current_user do
      check_memberships(conn, current_user)
    else
      conn
    end
  end

  defp check_memberships(conn, user) do
    # Skip check if already on onboarding page
    if conn.request_path =~ ~r{^/onboarding} do
      conn
    else
      case get_user_memberships(user.id) do
        [] ->
          conn
          |> put_flash(:info, "Please create your first organization to continue")
          |> redirect(to: "/onboarding/create-organization")
          |> halt()

        _memberships ->
          conn
      end
    end
  end

  defp get_user_memberships(user_id) do
    case Organizations.Membership
         |> Ash.Query.filter(user_id == ^user_id)
         |> Ash.read(authorize?: false) do
      {:ok, memberships} -> memberships
      {:error, _} -> []
    end
  end
end
