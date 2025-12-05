defmodule SaasStarterWeb.Auth.ForgotPasswordLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Forgot Password")
     |> assign(:email, "")
     |> assign(:sent, false)
     |> assign(:error, nil)}
  end

  def handle_event("validate", %{"email" => email}, socket) do
    {:noreply,
     socket
     |> assign(:email, email)
     |> assign(:error, nil)}
  end

  def handle_event("submit", %{"email" => email}, socket) do
    # Request password reset - this will trigger the email sender in the User resource
    case Accounts.User
         |> Ash.Query.for_read(:by_email, %{email: email})
         |> Ash.read_one() do
      {:ok, user} when not is_nil(user) ->
        # Request reset token
        case AshAuthentication.Strategy.Password.request_password_reset(
               user,
               Accounts.User,
               :password
             ) do
          :ok ->
            {:noreply,
             socket
             |> assign(:sent, true)
             |> assign(:email, email)}

          {:error, _} ->
            # Don't reveal errors for security
            {:noreply,
             socket
             |> assign(:sent, true)
             |> assign(:email, email)}
        end

      _ ->
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
            Forgot Password
          </h1>
          <p class="text-center text-sm text-base-content/70 mb-6">
            We'll send you a link to reset your password
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
                Send Reset Link
              </button>
            </form>
          </div>

          <div :if={@sent} class="space-y-4">
            <div class="alert alert-success">
              <div class="flex flex-col">
                <span class="font-semibold">Check your email!</span>
                <span class="text-sm">
                  If an account exists for <strong><%= @email %></strong>, you'll receive a password reset link shortly.
                </span>
              </div>
            </div>

            <p class="text-sm text-center text-base-content/70">
              The reset link will expire in 1 hour.
            </p>

            <div class="alert alert-info">
              <div class="flex flex-col text-sm">
                <span class="font-semibold">Development Mode</span>
                <span>Check <a href="/dev/mailbox" class="link" target="_blank">/dev/mailbox</a> for the reset link</span>
              </div>
            </div>
          </div>

          <div class="divider">OR</div>

          <div class="text-center space-y-2">
            <p class="text-sm">
              Remember your password?
              <a href="/login" class="link link-primary">Sign in</a>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
