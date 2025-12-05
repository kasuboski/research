defmodule SaasStarterWeb.Team.IndexLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Organizations

  def mount(_params, _session, socket) do
    current_org = socket.assigns.current_organization
    current_user = socket.assigns.current_user

    # Get all memberships and invites for this organization
    memberships = get_memberships(current_org.id)
    invites = get_invites(current_org.id, current_user)

    # Check if current user is owner
    current_membership = Enum.find(memberships, &(&1.user_id == current_user.id))
    is_owner = current_membership && current_membership.role == :owner

    {:ok,
     socket
     |> assign(:page_title, "Team")
     |> assign(:current_page, :team)
     |> assign(:memberships, memberships)
     |> assign(:invites, invites)
     |> assign(:is_owner, is_owner)
     |> assign(:show_invite_modal, false)}
  end

  defp get_memberships(org_id) do
    case Organizations.Membership
         |> Ash.Query.filter(organization_id == ^org_id)
         |> Ash.Query.load(:user)
         |> Ash.read(authorize?: false) do
      {:ok, memberships} -> memberships
      {:error, _} -> []
    end
  end

  defp get_invites(org_id, current_user) do
    case Organizations.Invite
         |> Ash.Query.filter(organization_id == ^org_id)
         |> Ash.read(actor: current_user, tenant: org_id) do
      {:ok, invites} ->
        # Filter out expired invites
        now = DateTime.utc_now()
        Enum.filter(invites, fn invite ->
          DateTime.compare(invite.expires_at, now) == :gt
        end)

      {:error, _} ->
        []
    end
  end

  def handle_event("show_invite_modal", _params, socket) do
    {:noreply, assign(socket, :show_invite_modal, true)}
  end

  def handle_event("remove_member", %{"id" => member_id}, socket) do
    current_user = socket.assigns.current_user
    current_org = socket.assigns.current_organization

    result =
      Organizations.Membership
      |> Ash.get(member_id, actor: current_user, tenant: current_org.id)
      |> case do
        {:ok, membership} ->
          Ash.destroy(membership, actor: current_user, tenant: current_org.id)

        error ->
          error
      end

    case result do
      {:ok, _} ->
        memberships = get_memberships(current_org.id)

        {:noreply,
         socket
         |> put_flash(:info, "Member removed successfully")
         |> assign(:memberships, memberships)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to remove member")}
    end
  end

  def handle_event("revoke_invite", %{"id" => invite_id}, socket) do
    current_user = socket.assigns.current_user
    current_org = socket.assigns.current_organization

    result =
      Organizations.Invite
      |> Ash.get(invite_id, actor: current_user, tenant: current_org.id)
      |> case do
        {:ok, invite} ->
          Ash.destroy(invite, actor: current_user, tenant: current_org.id)

        error ->
          error
      end

    case result do
      {:ok, _} ->
        invites = get_invites(current_org.id, current_user)

        {:noreply,
         socket
         |> put_flash(:info, "Invitation revoked")
         |> assign(:invites, invites)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to revoke invitation")}
    end
  end

  def handle_info({:invite_sent, email}, socket) do
    current_org = socket.assigns.current_organization
    current_user = socket.assigns.current_user

    invites = get_invites(current_org.id, current_user)

    {:noreply,
     socket
     |> put_flash(:info, "Invitation sent to #{email}")
     |> assign(:invites, invites)
     |> assign(:show_invite_modal, false)}
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
        <div class="flex justify-between items-center mb-8">
          <div>
            <h1 class="text-4xl font-bold mb-2">Team</h1>
            <p class="text-base-content/70">
              Manage members and invitations for <%= @current_organization.name %>
            </p>
          </div>

          <%= if @is_owner do %>
            <button
              phx-click="show_invite_modal"
              class="btn btn-primary gap-2"
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
                  d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
                >
                </path>
              </svg>
              Invite Member
            </button>
          <% end %>
        </div>
        <!-- Members Section -->
        <div class="card bg-base-100 shadow-xl mb-8">
          <div class="card-body">
            <h2 class="card-title text-2xl mb-4">
              Members (<%= length(@memberships) %>)
            </h2>

            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Member</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Joined</th>
                    <%= if @is_owner do %>
                      <th>Actions</th>
                    <% end %>
                  </tr>
                </thead>
                <tbody>
                  <%= for membership <- @memberships do %>
                    <tr>
                      <td>
                        <div class="flex items-center gap-3">
                          <div class="avatar placeholder">
                            <div class="bg-neutral-focus text-neutral-content rounded-full w-12">
                              <span class="text-sm">
                                <%= if membership.user.full_name do %>
                                  <%= membership.user.full_name
                                  |> String.split()
                                  |> Enum.map(&String.first/1)
                                  |> Enum.join() %>
                                <% else %>
                                  <%= String.first(membership.user.email) |> String.upcase() %>
                                <% end %>
                              </span>
                            </div>
                          </div>
                          <div>
                            <div class="font-bold">
                              <%= membership.user.full_name || "User" %>
                            </div>
                            <%= if membership.user_id == @current_user.id do %>
                              <div class="text-sm opacity-50">You</div>
                            <% end %>
                          </div>
                        </div>
                      </td>
                      <td><%= membership.user.email %></td>
                      <td>
                        <span class={[
                          "badge",
                          if(membership.role == :owner, do: "badge-primary", else: "badge-ghost")
                        ]}>
                          <%= membership.role |> to_string() |> String.capitalize() %>
                        </span>
                      </td>
                      <td>
                        <%= Calendar.strftime(membership.inserted_at, "%b %d, %Y") %>
                      </td>
                      <%= if @is_owner do %>
                        <td>
                          <%= if membership.user_id != @current_user.id do %>
                            <button
                              phx-click="remove_member"
                              phx-value-id={membership.id}
                              data-confirm="Are you sure you want to remove this member?"
                              class="btn btn-ghost btn-sm text-error"
                            >
                              Remove
                            </button>
                          <% end %>
                        </td>
                      <% end %>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <!-- Pending Invites Section -->
        <%= if @is_owner && length(@invites) > 0 do %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl mb-4">
                Pending Invitations (<%= length(@invites) %>)
              </h2>

              <div class="overflow-x-auto">
                <table class="table table-zebra w-full">
                  <thead>
                    <tr>
                      <th>Email</th>
                      <th>Role</th>
                      <th>Expires</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for invite <- @invites do %>
                      <tr>
                        <td><%= invite.email %></td>
                        <td>
                          <span class={[
                            "badge",
                            if(invite.role == :owner, do: "badge-primary", else: "badge-ghost")
                          ]}>
                            <%= invite.role |> to_string() |> String.capitalize() %>
                          </span>
                        </td>
                        <td>
                          <%= Calendar.strftime(invite.expires_at, "%b %d, %Y") %>
                        </td>
                        <td>
                          <button
                            phx-click="revoke_invite"
                            phx-value-id={invite.id}
                            data-confirm="Are you sure you want to revoke this invitation?"
                            class="btn btn-ghost btn-sm text-error"
                          >
                            Revoke
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        <% end %>
      </main>
      <!-- Invite Modal -->
      <.live_component
        module={SaasStarterWeb.Team.InviteModalComponent}
        id="invite-modal"
        current_organization={@current_organization}
        current_user={@current_user}
        show={@show_invite_modal}
      />
    </div>
    """
  end
end
