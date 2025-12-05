defmodule SaasStarterWeb.Team.AcceptInviteLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Organizations

  def mount(%{"token" => token}, _session, socket) do
    current_user = socket.assigns[:current_user]

    # Look up the invite by token
    case Organizations.Invite
         |> Ash.Query.for_read(:by_token, %{token: token})
         |> Ash.read_one(authorize?: false) do
      {:ok, nil} ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid or expired invitation")
         |> push_navigate(to: "/dashboard")}

      {:ok, invite} ->
        # Check if invite is expired
        if DateTime.compare(invite.expires_at, DateTime.utc_now()) == :lt do
          {:ok,
           socket
           |> put_flash(:error, "This invitation has expired")
           |> push_navigate(to: "/dashboard")}
        else
          # Load organization
          organization =
            Organizations.Organization
            |> Ash.get!(invite.organization_id, authorize?: false)

          {:ok,
           socket
           |> assign(:page_title, "Accept Invitation")
           |> assign(:invite, invite)
           |> assign(:organization, organization)
           |> assign(:accepting, false)
           |> assign(:error, nil)}
        end

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid invitation")
         |> push_navigate(to: "/dashboard")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_flash(:error, "Invalid invitation link")
     |> push_navigate(to: "/dashboard")}
  end

  def handle_event("accept", _params, socket) do
    current_user = socket.assigns.current_user
    invite = socket.assigns.invite

    # If user is not logged in, redirect to register with return path
    if is_nil(current_user) do
      {:noreply,
       socket
       |> put_flash(:info, "Please sign in or create an account to accept this invitation")
       |> push_navigate(to: "/register")}
    else
      # Accept the invite
      result =
        Organizations.Invite
        |> Ash.get(invite.id, authorize?: false)
        |> case do
          {:ok, invite} ->
            invite
            |> Ash.Changeset.for_update(:accept, %{user_id: current_user.id})
            |> Ash.update(authorize?: false)

          error ->
            error
        end

      case result do
        {:ok, _membership} ->
          organization = socket.assigns.organization

          {:noreply,
           socket
           |> put_flash(:info, "Successfully joined #{organization.name}!")
           |> push_navigate(to: "/#{organization.slug}/dashboard")}

        {:error, error} ->
          error_message =
            case error do
              %Ash.Error.Invalid{errors: errors} ->
                errors
                |> Enum.map(& &1.message)
                |> Enum.join(", ")

              _ ->
                "Failed to accept invitation"
            end

          {:noreply, assign(socket, :error, error_message)}
      end
    end
  end

  def handle_event("decline", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Invitation declined")
     |> push_navigate(to: "/dashboard")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 px-4">
      <div class="card w-full max-w-lg bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="text-center mb-6">
            <div class="avatar placeholder mb-4">
              <div class="bg-primary text-primary-content rounded-full w-20">
                <span class="text-3xl"><%= String.first(@organization.name) %></span>
              </div>
            </div>

            <h1 class="text-3xl font-bold mb-2">You're Invited!</h1>
            <p class="text-lg text-base-content/70">
              You've been invited to join
            </p>
            <p class="text-2xl font-bold text-primary mt-2">
              <%= @organization.name %>
            </p>
          </div>

          <div class="bg-base-200 rounded-lg p-4 mb-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-base-content/70">Role</p>
                <p class="font-semibold capitalize">
                  <%= @invite.role %>
                </p>
              </div>
              <div class="text-right">
                <p class="text-sm text-base-content/70">Expires</p>
                <p class="font-semibold">
                  <%= Calendar.strftime(@invite.expires_at, "%b %d, %Y") %>
                </p>
              </div>
            </div>
          </div>

          <div :if={@error} class="alert alert-error mb-4">
            <span><%= @error %></span>
          </div>

          <%= if @current_user do %>
            <div class="alert alert-info mb-4">
              <div class="flex flex-col">
                <span class="font-semibold">Signed in as:</span>
                <span class="text-sm"><%= @current_user.email %></span>
              </div>
            </div>

            <div class="flex gap-4">
              <button
                phx-click="decline"
                class="btn btn-ghost flex-1"
                disabled={@accepting}
              >
                Decline
              </button>
              <button
                phx-click="accept"
                class="btn btn-primary flex-1"
                disabled={@accepting}
              >
                <%= if @accepting, do: "Accepting...", else: "Accept Invitation" %>
              </button>
            </div>
          <% else %>
            <div class="space-y-4">
              <p class="text-center text-sm text-base-content/70">
                Sign in or create an account to accept this invitation
              </p>

              <div class="flex gap-4">
                <a href="/login" class="btn btn-outline flex-1">
                  Sign In
                </a>
                <a href="/register" class="btn btn-primary flex-1">
                  Create Account
                </a>
              </div>
            </div>
          <% end %>

          <div class="text-center mt-6">
            <p class="text-xs text-base-content/60">
              Invitations expire after 7 days
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
