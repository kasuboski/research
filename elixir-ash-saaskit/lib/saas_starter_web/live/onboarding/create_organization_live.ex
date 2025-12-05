defmodule SaasStarterWeb.Onboarding.CreateOrganizationLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Organizations

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    # Check if user already has organizations
    case get_user_memberships(current_user.id) do
      [] ->
        # No organizations, show onboarding form
        form = AshPhoenix.Form.for_create(Organizations.Organization, :create_with_owner)

        {:ok,
         socket
         |> assign(:page_title, "Create Your Organization")
         |> assign(:form, to_form(form))}

      memberships ->
        # User has organizations, redirect to first one
        first_membership = List.first(memberships)

        org =
          Organizations.Organization
          |> Ash.get!(first_membership.organization_id, authorize?: false)

        {:ok, push_navigate(socket, to: "/#{org.slug}/dashboard")}
    end
  end

  defp get_user_memberships(user_id) do
    case Organizations.Membership
         |> Ash.Query.filter(user_id == ^user_id)
         |> Ash.Query.load(:organization)
         |> Ash.read(authorize?: false) do
      {:ok, memberships} -> memberships
      {:error, _} -> []
    end
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = socket.assigns.form.source

    {:noreply,
     socket
     |> assign(:form, form |> AshPhoenix.Form.validate(params) |> to_form())}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    current_user = socket.assigns.current_user

    # Create organization with the current user as owner
    case Organizations.Organization
         |> Ash.Changeset.for_create(:create_with_owner, %{
           name: params["name"],
           user_id: current_user.id
         })
         |> Ash.create(actor: current_user) do
      {:ok, organization} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully!")
         |> push_navigate(to: "/#{organization.slug}/dashboard")}

      {:error, error} ->
        form =
          socket.assigns.form.source
          |> AshPhoenix.Form.add_form_error(error)

        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 px-4">
      <div class="card w-full max-w-2xl bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="text-center mb-8">
            <h1 class="text-4xl font-bold mb-2">Welcome!</h1>
            <p class="text-lg text-base-content/70">
              Let's get started by creating your first organization
            </p>
          </div>

          <div class="bg-base-200 rounded-lg p-6 mb-6">
            <div class="flex items-start space-x-4">
              <div class="flex-shrink-0">
                <svg
                  class="w-6 h-6 text-primary"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <div>
                <h3 class="font-semibold mb-1">What's an organization?</h3>
                <p class="text-sm text-base-content/70">
                  Organizations let you collaborate with your team. You can create multiple
                  organizations and invite team members to each one. Think of it as a workspace
                  for your projects.
                </p>
              </div>
            </div>
          </div>

          <.simple_form for={@form} phx-change="validate" phx-submit="submit">
            <.input
              field={@form[:name]}
              type="text"
              label="Organization Name"
              placeholder="Acme Inc."
              required
            />

            <div class="text-sm text-base-content/70 -mt-4">
              You can always change this later or create additional organizations.
            </div>

            <:actions>
              <.button type="submit" class="btn btn-primary btn-lg w-full">
                Create Organization
              </.button>
            </:actions>
          </.simple_form>

          <div class="text-center mt-6">
            <p class="text-sm text-base-content/70">
              By creating an organization, you'll be assigned as the owner with full permissions.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
