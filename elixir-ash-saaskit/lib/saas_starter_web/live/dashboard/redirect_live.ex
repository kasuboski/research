defmodule SaasStarterWeb.Dashboard.RedirectLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Organizations

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    # Get user's first organization
    case get_first_organization(current_user.id) do
      nil ->
        # No organizations, redirect to onboarding
        {:ok, push_navigate(socket, to: "/onboarding/create-organization")}

      org ->
        # Redirect to first organization's dashboard
        {:ok, push_navigate(socket, to: "/#{org.slug}/dashboard")}
    end
  end

  defp get_first_organization(user_id) do
    case Organizations.Membership
         |> Ash.Query.filter(user_id == ^user_id)
         |> Ash.Query.load(:organization)
         |> Ash.Query.limit(1)
         |> Ash.read(authorize?: false) do
      {:ok, [membership | _]} -> membership.organization
      {:ok, []} -> nil
      {:error, _} -> nil
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="text-center">
        <span class="loading loading-spinner loading-lg text-primary"></span>
        <p class="mt-4 text-lg">Redirecting...</p>
      </div>
    </div>
    """
  end
end
