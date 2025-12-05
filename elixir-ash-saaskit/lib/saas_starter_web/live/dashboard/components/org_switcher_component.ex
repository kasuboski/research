defmodule SaasStarterWeb.Dashboard.Components.OrgSwitcherComponent do
  use SaasStarterWeb, :live_component

  alias SaasStarter.Organizations

  def update(assigns, socket) do
    current_user = assigns.current_user
    current_org = assigns[:current_organization]

    # Get all organizations the user is a member of
    organizations = get_user_organizations(current_user.id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:current_organization, current_org)
     |> assign(:organizations, organizations)
     |> assign(:dropdown_open, false)}
  end

  defp get_user_organizations(user_id) do
    case Organizations.Membership
         |> Ash.Query.filter(user_id == ^user_id)
         |> Ash.Query.load(:organization)
         |> Ash.read(authorize?: false) do
      {:ok, memberships} ->
        Enum.map(memberships, & &1.organization)

      {:error, _} ->
        []
    end
  end

  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, !socket.assigns.dropdown_open)}
  end

  def render(assigns) do
    ~H"""
    <div class="dropdown dropdown-end" phx-click-away="toggle_dropdown" phx-target={@myself}>
      <label
        tabindex="0"
        class="btn btn-ghost gap-2 normal-case"
        phx-click="toggle_dropdown"
        phx-target={@myself}
      >
        <div class="avatar placeholder">
          <div class="bg-primary text-primary-content rounded-full w-8">
            <span class="text-xs">
              <%= if @current_organization do %>
                <%= String.first(@current_organization.name) %>
              <% else %>
                ?
              <% end %>
            </span>
          </div>
        </div>
        <div class="flex flex-col items-start">
          <span class="text-sm font-semibold">
            <%= if @current_organization, do: @current_organization.name, else: "Select Organization" %>
          </span>
        </div>
        <svg
          class="w-4 h-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7">
          </path>
        </svg>
      </label>

      <ul
        :if={@dropdown_open}
        tabindex="0"
        class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-64 mt-2"
      >
        <li class="menu-title">
          <span>Your Organizations</span>
        </li>
        <%= for org <- @organizations do %>
          <li>
            <a
              href={"/#{org.slug}/dashboard"}
              class={
                if @current_organization && org.id == @current_organization.id,
                  do: "active",
                  else: ""
              }
            >
              <div class="avatar placeholder">
                <div class="bg-primary text-primary-content rounded-full w-8">
                  <span class="text-xs"><%= String.first(org.name) %></span>
                </div>
              </div>
              <div class="flex flex-col">
                <span class="font-semibold"><%= org.name %></span>
                <span class="text-xs opacity-60">@<%= org.slug %></span>
              </div>
            </a>
          </li>
        <% end %>

        <div class="divider my-1"></div>

        <li>
          <a href="/onboarding/create-organization" class="text-primary">
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
                d="M12 4v16m8-8H4"
              >
              </path>
            </svg>
            Create New Organization
          </a>
        </li>
      </ul>
    </div>
    """
  end
end
