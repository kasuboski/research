defmodule SaasStarterWeb.Settings.SecurityLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Security Settings")
     |> assign(:current_page, :security)
     |> assign(:current_password, "")
     |> assign(:new_password, "")
     |> assign(:new_password_confirmation, "")
     |> assign(:error, nil)
     |> assign(:success, false)}
  end

  def handle_event("validate", params, socket) do
    {:noreply,
     socket
     |> assign(:current_password, params["current_password"] || "")
     |> assign(:new_password, params["new_password"] || "")
     |> assign(:new_password_confirmation, params["new_password_confirmation"] || "")
     |> assign(:error, nil)}
  end

  def handle_event("submit", params, socket) do
    current_user = socket.assigns.current_user
    current_password = params["current_password"]
    new_password = params["new_password"]
    new_password_confirmation = params["new_password_confirmation"]

    # Validate passwords match
    if new_password != new_password_confirmation do
      {:noreply,
       socket
       |> assign(:error, "New passwords do not match")
       |> assign(:new_password, "")
       |> assign(:new_password_confirmation, "")}
    else
      # Verify current password first
      case AshAuthentication.authenticate(Accounts.User, :password, %{
             "email" => current_user.email,
             "password" => current_password
           }) do
        {:ok, _user} ->
          # Current password is correct, update to new password
          case update_password(current_user, new_password) do
            {:ok, _user} ->
              {:noreply,
               socket
               |> assign(:success, true)
               |> assign(:current_password, "")
               |> assign(:new_password, "")
               |> assign(:new_password_confirmation, "")
               |> assign(:error, nil)
               |> put_flash(:info, "Password changed successfully!")}

            {:error, error} ->
              error_message =
                case error do
                  %Ash.Error.Invalid{errors: errors} ->
                    errors
                    |> Enum.map(& &1.message)
                    |> Enum.join(", ")

                  _ ->
                    "Failed to update password"
                end

              {:noreply,
               socket
               |> assign(:error, error_message)
               |> assign(:new_password, "")
               |> assign(:new_password_confirmation, "")}
          end

        {:error, _} ->
          {:noreply,
           socket
           |> assign(:error, "Current password is incorrect")
           |> assign(:current_password, "")}
      end
    end
  end

  defp update_password(user, new_password) do
    # Use Ash's update action to change password
    user
    |> Ash.Changeset.for_update(:update, %{hashed_password: new_password})
    |> Ash.update(actor: user)
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
            <h1 class="text-4xl font-bold mb-2">Security Settings</h1>
            <p class="text-base-content/70">
              Manage your password and security preferences
            </p>
          </div>
          <!-- Change Password Card -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-6">Change Password</h2>

              <form phx-change="validate" phx-submit="submit" class="space-y-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text font-semibold">Current Password</span>
                  </label>
                  <input
                    type="password"
                    name="current_password"
                    value={@current_password}
                    class="input input-bordered w-full"
                    required
                    autocomplete="current-password"
                  />
                </div>

                <div class="divider"></div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text font-semibold">New Password</span>
                  </label>
                  <input
                    type="password"
                    name="new_password"
                    value={@new_password}
                    class="input input-bordered w-full"
                    required
                    minlength="8"
                    placeholder="At least 8 characters"
                    autocomplete="new-password"
                  />
                </div>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text font-semibold">Confirm New Password</span>
                  </label>
                  <input
                    type="password"
                    name="new_password_confirmation"
                    value={@new_password_confirmation}
                    class="input input-bordered w-full"
                    required
                    minlength="8"
                    placeholder="Re-enter your new password"
                    autocomplete="new-password"
                  />
                </div>

                <div :if={@error} class="alert alert-error">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="stroke-current shrink-0 h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span><%= @error %></span>
                </div>

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
                  <div>
                    <p class="font-semibold">Password Requirements:</p>
                    <ul class="list-disc list-inside text-xs mt-1">
                      <li>At least 8 characters long</li>
                      <li>Mix of letters and numbers recommended</li>
                    </ul>
                  </div>
                </div>

                <div class="flex justify-end">
                  <button type="submit" class="btn btn-primary">
                    Update Password
                  </button>
                </div>
              </form>
            </div>
          </div>
          <!-- Two-Factor Authentication Card (Future) -->
          <div class="card bg-base-100 shadow-xl mt-8">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-4">Two-Factor Authentication</h2>

              <div class="flex items-center justify-between">
                <div>
                  <p class="font-semibold">Enable 2FA</p>
                  <p class="text-sm text-base-content/70">
                    Add an extra layer of security to your account
                  </p>
                </div>
                <button class="btn btn-outline btn-sm" disabled>
                  Coming Soon
                </button>
              </div>
            </div>
          </div>
          <!-- Sessions Card (Future) -->
          <div class="card bg-base-100 shadow-xl mt-8">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-4">Active Sessions</h2>

              <div class="flex items-center justify-between">
                <div>
                  <p class="font-semibold">Manage Sessions</p>
                  <p class="text-sm text-base-content/70">
                    View and manage your active login sessions
                  </p>
                </div>
                <button class="btn btn-outline btn-sm" disabled>
                  Coming Soon
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
