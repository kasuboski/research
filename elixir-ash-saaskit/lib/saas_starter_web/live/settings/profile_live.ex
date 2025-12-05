defmodule SaasStarterWeb.Settings.ProfileLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    form = AshPhoenix.Form.for_update(current_user, :update_profile)

    {:ok,
     socket
     |> assign(:page_title, "Profile Settings")
     |> assign(:current_page, :profile)
     |> assign(:form, to_form(form))}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = socket.assigns.form.source

    {:noreply,
     socket
     |> assign(:form, form |> AshPhoenix.Form.validate(params) |> to_form())}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    current_user = socket.assigns.current_user

    case current_user
         |> Ash.Changeset.for_update(:update_profile, %{
           full_name: params["full_name"],
           avatar_url: params["avatar_url"],
           email: current_user.email
         })
         |> Ash.update(actor: current_user) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully!")
         |> assign(:current_user, updated_user)
         |> assign(:form, to_form(AshPhoenix.Form.for_update(updated_user, :update_profile)))}

      {:error, error} ->
        form =
          socket.assigns.form.source
          |> AshPhoenix.Form.add_form_error(error)

        {:noreply,
         socket
         |> put_flash(:error, "Failed to update profile")
         |> assign(:form, to_form(form))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-base-100">
      <!-- Sidebar - Only show if we have an organization -->
      <%= if assigns[:current_organization] do %>
        <.live_component
          module={SaasStarterWeb.Dashboard.Components.SidebarComponent}
          id="sidebar"
          current_user={@current_user}
          current_organization={@current_organization}
          current_page={@current_page}
        />
      <% end %>
      <!-- Main Content -->
      <main class="flex-1 p-8">
        <div class="max-w-2xl mx-auto">
          <!-- Page Header -->
          <div class="mb-8">
            <h1 class="text-4xl font-bold mb-2">Profile Settings</h1>
            <p class="text-base-content/70">
              Manage your personal information
            </p>
          </div>
          <!-- Profile Form Card -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-6">Personal Information</h2>

              <.simple_form for={@form} phx-change="validate" phx-submit="submit">
                <div class="form-control mb-4">
                  <label class="label">
                    <span class="label-text font-semibold">Email</span>
                  </label>
                  <input
                    type="email"
                    value={@current_user.email}
                    class="input input-bordered w-full"
                    disabled
                  />
                  <label class="label">
                    <span class="label-text-alt text-base-content/70">
                      Email cannot be changed at this time
                    </span>
                  </label>
                </div>

                <.input
                  field={@form[:full_name]}
                  type="text"
                  label="Full Name"
                  placeholder="John Doe"
                />

                <.input
                  field={@form[:avatar_url]}
                  type="url"
                  label="Avatar URL (optional)"
                  placeholder="https://example.com/avatar.jpg"
                />

                <div class="alert alert-info text-sm">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    class="stroke-current shrink-0 w-6 h-6"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    >
                    </path>
                  </svg>
                  <span>
                    Your profile information is visible to members of organizations you belong to.
                  </span>
                </div>

                <:actions>
                  <div class="flex justify-end gap-2 w-full">
                    <.button type="submit" class="btn btn-primary">
                      Save Changes
                    </.button>
                  </div>
                </:actions>
              </.simple_form>
            </div>
          </div>
          <!-- Account Actions Card -->
          <div class="card bg-base-100 shadow-xl mt-8">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-4">Account Actions</h2>

              <div class="space-y-4">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-semibold">Change Password</p>
                    <p class="text-sm text-base-content/70">Update your password and security settings</p>
                  </div>
                  <a href="/settings/security" class="btn btn-outline btn-sm">
                    Manage Security
                  </a>
                </div>

                <div class="divider"></div>

                <div class="flex items-center justify-between">
                  <div>
                    <p class="font-semibold text-error">Delete Account</p>
                    <p class="text-sm text-base-content/70">
                      Permanently delete your account and all associated data
                    </p>
                  </div>
                  <button class="btn btn-outline btn-error btn-sm" disabled>
                    Delete Account
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
