defmodule SaasStarterWeb.Auth.RegisterLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(_params, _session, socket) do
    # Redirect if already authenticated
    if socket.assigns[:current_user] do
      {:ok, push_navigate(socket, to: "/dashboard")}
    else
      form = AshPhoenix.Form.for_create(Accounts.User, :register_with_password)

      {:ok,
       socket
       |> assign(:page_title, "Sign Up")
       |> assign(:form, to_form(form))}
    end
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = socket.assigns.form.source

    {:noreply,
     socket
     |> assign(:form, form |> AshPhoenix.Form.validate(params) |> to_form())}
  end

  def handle_event("submit", %{"form" => params}, socket) do
    form = socket.assigns.form.source

    case AshPhoenix.Form.submit(form, params: params) do
      {:ok, user} ->
        # Generate token and store in session
        case AshAuthentication.authenticate(Accounts.User, :password, params) do
          {:ok, authenticated_user} ->
            token = AshAuthentication.user_to_token(authenticated_user)

            {:noreply,
             socket
             |> put_flash(:info, "Account created successfully! Welcome!")
             |> redirect(to: "/auth/success?token=#{token}")}

          {:error, _} ->
            # User created but couldn't authenticate - have them log in
            {:noreply,
             socket
             |> put_flash(:info, "Account created! Please sign in.")
             |> push_navigate(to: "/login")}
        end

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 px-4">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-3xl font-bold text-center justify-center mb-6">
            Create Your Account
          </h1>

          <.simple_form for={@form} phx-change="validate" phx-submit="submit">
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input
              field={@form[:hashed_password]}
              type="password"
              label="Password"
              required
              placeholder="At least 8 characters"
            />

            <:actions>
              <.button type="submit" class="btn btn-primary w-full">
                Sign Up
              </.button>
            </:actions>
          </.simple_form>

          <div class="divider">OR</div>

          <div class="text-center space-y-2">
            <p class="text-sm">
              Already have an account?
              <a href="/login" class="link link-primary">Sign in</a>
            </p>
            <p class="text-sm">
              <a href="/magic-link" class="link link-primary">Sign in with magic link</a>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
