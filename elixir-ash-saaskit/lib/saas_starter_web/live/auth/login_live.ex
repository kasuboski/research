defmodule SaasStarterWeb.Auth.LoginLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(_params, _session, socket) do
    # Redirect if already authenticated
    if socket.assigns[:current_user] do
      {:ok, push_navigate(socket, to: "/dashboard")}
    else
      {:ok,
       socket
       |> assign(:page_title, "Sign In")
       |> assign(:email, "")
       |> assign(:password, "")
       |> assign(:error, nil)}
    end
  end

  def handle_event("validate", %{"email" => email, "password" => password}, socket) do
    {:noreply,
     socket
     |> assign(:email, email)
     |> assign(:password, password)
     |> assign(:error, nil)}
  end

  def handle_event("submit", %{"email" => email, "password" => password}, socket) do
    case AshAuthentication.authenticate(Accounts.User, :password, %{
           "email" => email,
           "password" => password
         }) do
      {:ok, user} ->
        token = AshAuthentication.user_to_token(user)

        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> redirect(to: "/auth/success?token=#{token}")}

      {:error, _error} ->
        {:noreply,
         socket
         |> assign(:error, "Invalid email or password")
         |> assign(:password, "")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 px-4">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-3xl font-bold text-center justify-center mb-6">
            Sign In
          </h1>

          <form phx-change="validate" phx-submit="submit" class="space-y-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">Email</span>
              </label>
              <input
                type="email"
                name="email"
                value={@email}
                class="input input-bordered w-full"
                required
                autocomplete="email"
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">Password</span>
              </label>
              <input
                type="password"
                name="password"
                value={@password}
                class="input input-bordered w-full"
                required
                autocomplete="current-password"
              />
            </div>

            <div :if={@error} class="alert alert-error">
              <span><%= @error %></span>
            </div>

            <div class="text-right">
              <a href="/forgot-password" class="link link-primary text-sm">
                Forgot password?
              </a>
            </div>

            <button type="submit" class="btn btn-primary w-full">
              Sign In
            </button>
          </form>

          <div class="divider">OR</div>

          <div class="text-center space-y-2">
            <p class="text-sm">
              Don't have an account?
              <a href="/register" class="link link-primary">Sign up</a>
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
