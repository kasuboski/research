defmodule SaasStarterWeb.Dashboard.IndexLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Organizations

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_org = socket.assigns.current_organization

    # Get membership info for the current user in this org
    membership = get_membership(current_org.id, current_user.id)
    member_count = get_member_count(current_org.id)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:current_page, :dashboard)
     |> assign(:membership, membership)
     |> assign(:member_count, member_count)}
  end

  defp get_membership(org_id, user_id) do
    case Organizations.Membership
         |> Ash.Query.filter(organization_id == ^org_id and user_id == ^user_id)
         |> Ash.read_one(authorize?: false) do
      {:ok, membership} -> membership
      {:error, _} -> nil
    end
  end

  defp get_member_count(org_id) do
    case Organizations.Membership
         |> Ash.Query.filter(organization_id == ^org_id)
         |> Ash.read(authorize?: false) do
      {:ok, memberships} -> length(memberships)
      {:error, _} -> 0
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-base-100">
      <!-- Sidebar -->
      <.live_component
        module={SaasStarterWeb.Dashboard.Components.SidebarComponent}
        id="sidebar"
        current_user={@current_user}
        current_organization={@current_organization}
        current_page={@current_page}
      />
      <!-- Main Content -->
      <main class="flex-1 p-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-4xl font-bold mb-2">
            Welcome to <%= @current_organization.name %>
          </h1>
          <p class="text-base-content/70">
            Here's an overview of your organization
          </p>
        </div>
        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <!-- Members Card -->
          <div class="stats shadow">
            <div class="stat">
              <div class="stat-figure text-primary">
                <svg
                  class="w-8 h-8"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                  >
                  </path>
                </svg>
              </div>
              <div class="stat-title">Team Members</div>
              <div class="stat-value text-primary"><%= @member_count %></div>
              <div class="stat-desc">
                <a href={"/#{@current_organization.slug}/team"} class="link link-primary">
                  Manage team
                </a>
              </div>
            </div>
          </div>
          <!-- Role Card -->
          <div class="stats shadow">
            <div class="stat">
              <div class="stat-figure text-secondary">
                <svg
                  class="w-8 h-8"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  >
                  </path>
                </svg>
              </div>
              <div class="stat-title">Your Role</div>
              <div class="stat-value text-secondary capitalize">
                <%= if @membership, do: @membership.role, else: "N/A" %>
              </div>
              <div class="stat-desc">
                <%= if @membership && @membership.role == :owner,
                  do: "Full access",
                  else: "Standard access" %>
              </div>
            </div>
          </div>
          <!-- Status Card -->
          <div class="stats shadow">
            <div class="stat">
              <div class="stat-figure text-accent">
                <svg
                  class="w-8 h-8"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  >
                  </path>
                </svg>
              </div>
              <div class="stat-title">Billing Status</div>
              <div class="stat-value text-accent capitalize">
                <%= @current_organization.billing_status %>
              </div>
              <div class="stat-desc">
                <%= case @current_organization.billing_status do %>
                  <% :trialing -> %>
                    Trial period active
                  <% :active -> %>
                    Subscription active
                  <% _ -> %>
                    Check billing settings
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <!-- Quick Actions -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-2xl mb-4">Quick Actions</h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= if @membership && @membership.role == :owner do %>
                <a
                  href={"/#{@current_organization.slug}/team"}
                  class="btn btn-outline btn-primary justify-start gap-4"
                >
                  <svg
                    class="w-6 h-6"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
                    >
                    </path>
                  </svg>
                  <div class="flex flex-col items-start">
                    <span class="font-semibold">Invite Team Members</span>
                    <span class="text-xs opacity-70">Add people to your organization</span>
                  </div>
                </a>
              <% end %>

              <a href="/settings/profile" class="btn btn-outline justify-start gap-4">
                <svg
                  class="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  >
                  </path>
                </svg>
                <div class="flex flex-col items-start">
                  <span class="font-semibold">Update Profile</span>
                  <span class="text-xs opacity-70">Manage your personal information</span>
                </div>
              </a>

              <a
                href={"/#{@current_organization.slug}/team"}
                class="btn btn-outline justify-start gap-4"
              >
                <svg
                  class="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  >
                  </path>
                </svg>
                <div class="flex flex-col items-start">
                  <span class="font-semibold">View Team</span>
                  <span class="text-xs opacity-70">See all organization members</span>
                </div>
              </a>

              <a href="/settings/security" class="btn btn-outline justify-start gap-4">
                <svg
                  class="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  >
                  </path>
                </svg>
                <div class="flex flex-col items-start">
                  <span class="font-semibold">Security Settings</span>
                  <span class="text-xs opacity-70">Change password and security options</span>
                </div>
              </a>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
