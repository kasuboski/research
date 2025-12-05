defmodule SaasStarterWeb.Auth.MagicLinkLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(_params, _session, socket) do
    # Redirect if already authenticated
    if socket.assigns[:current_user] do
      {:ok, push_navigate(socket, to: "/dashboard")}
    else
      {:ok,
       socket
       |> assign(:page_title, "Magic Link Sign In")
       |> assign(:email, "")
       |> assign(:sent, false)
       |> assign(:error, nil)}
    end
  end

  def handle_event("validate", %{"email" => email}, socket) do
    {:noreply,
     socket
     |> assign(:email, email)
     |> assign(:error, nil)}
  end

  def handle_event("submit", %{"email" => email}, socket) do
    # Request magic link - this will trigger the email sender in the User resource
    case Accounts.User
         |> Ash.ActionInput.for_action(:request_magic_link, %{email: email})
         |> Ash.run_action() do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:sent, true)
         |> assign(:email, email)}

      {:error, _error} ->
        # Don't reveal if email exists or not for security
        {:noreply,
         socket
         |> assign(:sent, true)
         |> assign(:email, email)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 px-4">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-3xl font-bold text-center justify-center mb-2">
            Magic Link Sign In
          </h1>
          <p class="text-center text-sm text-base-content/70 mb-6">
            Sign in without a password
          </p>

          <div :if={!@sent}>
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
                  placeholder="your@email.com"
                />
              </div>

              <div :if={@error} class="alert alert-error">
                <span><%= @error %></span>
              </div>

              <button type="submit" class="btn btn-primary w-full">
                Send Magic Link
              </button>
            </form>
          </div>

          <div :if={@sent} class="space-y-4">
            <div class="alert alert-success">
              <div class="flex flex-col">
                <span class="font-semibold">Check your email!</span>
                <span class="text-sm">
                  We've sent a magic link to <strong><%= @email %></strong>
                </span>
              </div>
            </div>

            <p class="text-sm text-center text-base-content/70">
              Click the link in the email to sign in. The link will expire in 15 minutes.
            </p>

            <div class="alert alert-info">
              <div class="flex flex-col text-sm">
                <span class="font-semibold">Development Mode</span>
                <span>Check <a href="/dev/mailbox" class="link" target="_blank">/dev/mailbox</a> for the magic link</span>
              </div>
            </div>

            <button phx-click="validate" phx-value-email="" class="btn btn-ghost btn-sm w-full">
              Send to a different email
            </button>
          </div>

          <div class="divider">OR</div>

          <div class="text-center space-y-2">
            <p class="text-sm">
              <a href="/login" class="link link-primary">Sign in with password</a>
            </p>
            <p class="text-sm">
              Don't have an account?
              <a href="/register" class="link link-primary">Sign up</a>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
