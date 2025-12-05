defmodule SaasStarterWeb.Plugs.LoadTenant do
  @moduledoc """
  Plug to resolve organization from URL slug and set tenant context.

  This plug:
  - Extracts the org_slug from URL path params
  - Looks up the organization by slug
  - Verifies the current user has access to this organization
  - Sets :current_organization and :tenant in conn assigns

  Should be used in pipelines that require tenant context.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias SaasStarter.Organizations

  def init(opts), do: opts

  def call(conn, _opts) do
    org_slug = conn.path_params["org_slug"]

    if org_slug do
      load_organization(conn, org_slug)
    else
      conn
    end
  end

  defp load_organization(conn, slug) do
    current_user = conn.assigns[:current_user]

    case Organizations.Organization
         |> Ash.Query.for_read(:by_slug, %{slug: slug})
         |> Ash.read_one(actor: current_user) do
      {:ok, nil} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: "/dashboard")
        |> halt()

      {:ok, organization} ->
        # Verify user has membership
        case has_membership?(organization.id, current_user.id) do
          true ->
            conn
            |> assign(:current_organization, organization)
            |> assign(:tenant, organization.id)

          false ->
            conn
            |> put_flash(:error, "You don't have access to this organization")
            |> redirect(to: "/dashboard")
            |> halt()
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, "Unable to load organization")
        |> redirect(to: "/dashboard")
        |> halt()
    end
  end

  defp has_membership?(org_id, user_id) do
    case Organizations.Membership
         |> Ash.Query.filter(organization_id == ^org_id and user_id == ^user_id)
         |> Ash.read_one(authorize?: false) do
      {:ok, nil} -> false
      {:ok, _membership} -> true
      {:error, _} -> false
    end
  end
end
