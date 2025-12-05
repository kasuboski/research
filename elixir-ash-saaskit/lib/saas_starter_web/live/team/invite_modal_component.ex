defmodule SaasStarterWeb.Team.InviteModalComponent do
  use SaasStarterWeb, :live_component

  alias SaasStarter.Organizations

  def update(assigns, socket) do
    form = AshPhoenix.Form.for_create(Organizations.Invite, :create)

    {:ok,
     socket
     |> assign(:current_organization, assigns.current_organization)
     |> assign(:current_user, assigns.current_user)
     |> assign(:form, to_form(form))
     |> assign(:show, assigns[:show] || false)}
  end

  def handle_event("show", _params, socket) do
    {:noreply, assign(socket, :show, true)}
  end

  def handle_event("hide", _params, socket) do
    {:noreply, assign(socket, :show, false)}
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = socket.assigns.form.source

    {:noreply,
     socket
     |> assign(:form, form |> AshPhoenix.Form.validate(params) |> to_form())}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    current_org = socket.assigns.current_organization
    current_user = socket.assigns.current_user

    # Create invite
    case Organizations.Invite
         |> Ash.Changeset.for_create(:create, %{
           email: params["email"],
           role: String.to_existing_atom(params["role"] || "member"),
           organization_id: current_org.id
         })
         |> Ash.create(actor: current_user, tenant: current_org.id) do
      {:ok, _invite} ->
        send(self(), {:invite_sent, params["email"]})

        {:noreply,
         socket
         |> assign(:show, false)
         |> assign(:form, to_form(AshPhoenix.Form.for_create(Organizations.Invite, :create)))}

      {:error, error} ->
        form =
          socket.assigns.form.source
          |> AshPhoenix.Form.add_form_error(error)

        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <!-- Modal -->
      <div :if={@show} class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Invite Team Member</h3>

          <.simple_form for={@form} phx-change="validate" phx-submit="submit" phx-target={@myself}>
            <.input field={@form[:email]} type="email" label="Email" required />

            <.input
              field={@form[:role]}
              type="select"
              label="Role"
              options={[{"Member", "member"}, {"Owner", "owner"}]}
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
              <div>
                <p class="font-semibold">Role Permissions:</p>
                <ul class="list-disc list-inside text-xs mt-1">
                  <li><strong>Owner:</strong> Full access, can invite and remove members</li>
                  <li><strong>Member:</strong> Standard access to organization</li>
                </ul>
              </div>
            </div>

            <:actions>
              <div class="flex justify-end gap-2 w-full">
                <button
                  type="button"
                  class="btn btn-ghost"
                  phx-click="hide"
                  phx-target={@myself}
                >
                  Cancel
                </button>
                <.button type="submit" class="btn btn-primary">
                  Send Invitation
                </.button>
              </div>
            </:actions>
          </.simple_form>
        </div>
        <div class="modal-backdrop" phx-click="hide" phx-target={@myself}></div>
      </div>
    </div>
    """
  end
end
