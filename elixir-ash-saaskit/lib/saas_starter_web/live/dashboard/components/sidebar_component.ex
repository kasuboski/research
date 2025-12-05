defmodule SaasStarterWeb.Dashboard.Components.SidebarComponent do
  use SaasStarterWeb, :live_component

  def render(assigns) do
    ~H"""
    <aside class="w-64 bg-base-200 min-h-screen flex flex-col">
      <!-- Logo / Brand -->
      <div class="p-4 border-b border-base-300">
        <h1 class="text-2xl font-bold text-primary">SaaS Starter</h1>
      </div>

      <!-- Organization Switcher -->
      <div class="p-4 border-b border-base-300">
        <.live_component
          module={SaasStarterWeb.Dashboard.Components.OrgSwitcherComponent}
          id="org-switcher"
          current_user={@current_user}
          current_organization={@current_organization}
        />
      </div>

      <!-- Main Navigation -->
      <nav class="flex-1 p-4">
        <ul class="menu menu-compact">
          <li>
            <a
              href={"/#{@current_organization.slug}/dashboard"}
              class={if @current_page == :dashboard, do: "active", else: ""}
            >
              <svg
                class="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                >
                </path>
              </svg>
              Dashboard
            </a>
          </li>

          <li>
            <a
              href={"/#{@current_organization.slug}/team"}
              class={if @current_page == :team, do: "active", else: ""}
            >
              <svg
                class="w-5 h-5"
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
              Team
            </a>
          </li>

          <div class="divider my-2"></div>

          <li class="menu-title">
            <span>Account</span>
          </li>

          <li>
            <a
              href="/settings/profile"
              class={if @current_page == :profile, do: "active", else: ""}
            >
              <svg
                class="w-5 h-5"
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
              Profile
            </a>
          </li>

          <li>
            <a
              href="/settings/security"
              class={if @current_page == :security, do: "active", else: ""}
            >
              <svg
                class="w-5 h-5"
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
              Security
            </a>
          </li>
        </ul>
      </nav>

      <!-- User Menu -->
      <div class="p-4 border-t border-base-300">
        <div class="dropdown dropdown-top dropdown-end w-full">
          <label tabindex="0" class="btn btn-ghost gap-2 w-full justify-start normal-case">
            <div class="avatar placeholder">
              <div class="bg-neutral-focus text-neutral-content rounded-full w-10">
                <span class="text-sm">
                  <%= if @current_user.full_name do %>
                    <%= @current_user.full_name |> String.split() |> Enum.map(&String.first/1) |> Enum.join() %>
                  <% else %>
                    <%= String.first(@current_user.email) |> String.upcase() %>
                  <% end %>
                </span>
              </div>
            </div>
            <div class="flex flex-col items-start flex-1">
              <span class="text-sm font-semibold truncate max-w-[150px]">
                <%= @current_user.full_name || "User" %>
              </span>
              <span class="text-xs opacity-60 truncate max-w-[150px]">
                <%= @current_user.email %>
              </span>
            </div>
          </label>

          <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
            <li>
              <a href="/settings/profile">
                <svg
                  class="w-4 h-4"
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
                Profile Settings
              </a>
            </li>
            <div class="divider my-1"></div>
            <li>
              <a href="/sign-out" class="text-error">
                <svg
                  class="w-4 h-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
                  >
                  </path>
                </svg>
                Sign Out
              </a>
            </li>
          </ul>
        </div>
      </div>
    </aside>
    """
  end
end
