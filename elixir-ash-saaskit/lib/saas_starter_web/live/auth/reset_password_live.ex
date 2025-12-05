defmodule SaasStarterWeb.Auth.ResetPasswordLive do
  use SaasStarterWeb, :live_view

  alias SaasStarter.Accounts

  def mount(%{"token" => token}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Reset Password")
     |> assign(:token, token)
     |> assign(:password, "")
     |> assign(:password_confirmation, "")
     |> assign(:error, nil)
     |> assign(:success, false)}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_flash(:error, "Invalid or missing reset token")
     |> push_navigate(to: "/login")}
  end

  def handle_event("validate", params, socket) do
    {:noreply,
     socket
     |> assign(:password, params["password"] || "")
     |> assign(:password_confirmation, params["password_confirmation"] || "")
     |> assign(:error, nil)}
  end

  def handle_event("submit", %{"password" => password, "password_confirmation" => confirmation}, socket) do
    if password == confirmation do
      # Reset password using AshAuthentication
      case AshAuthentication.Strategy.Password.reset_password(
             Accounts.User,
             :password,
             %{
               "reset_token" => socket.assigns.token,
               "password" => password,
               "password_confirmation" => confirmation
             }
           ) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> assign(:success, true)
           |> put_flash(:info, "Password reset successfully! Please sign in.")}

        {:error, error} ->
          error_message =
            case error do
              %Ash.Error.Invalid{errors: errors} ->
                errors
                |> Enum.map(& &1.message)
                |> Enum.join(", ")

              _ ->
                "Invalid or expired reset token"
            end

          {:noreply, assign(socket, :error, error_message)}
      end
    else
      {:noreply, assign(socket, :error, "Passwords do not match")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 px-4">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="card-title text-3xl font-bold text-center justify-center mb-2">
            Reset Password
          </h1>
          <p class="text-center text-sm text-base-content/70 mb-6">
            Enter your new password below
          </p>

          <div :if={!@success}>
            <form phx-change="validate" phx-submit="submit" class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold">New Password</span>
                </label>
                <input
                  type="password"
                  name="password"
                  value={@password}
                  class="input input-bordered w-full"
                  required
                  minlength="8"
                  placeholder="At least 8 characters"
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text font-semibold">Confirm Password</span>
                </label>
                <input
                  type="password"
                  name="password_confirmation"
                  value={@password_confirmation}
                  class="input input-bordered w-full"
                  required
                  minlength="8"
                  placeholder="Re-enter your password"
                />
              </div>

              <div :if={@error} class="alert alert-error">
                <span><%= @error %></span>
              </div>

              <button type="submit" class="btn btn-primary w-full">
                Reset Password
              </button>
            </form>
          </div>

          <div :if={@success} class="space-y-4">
            <div class="alert alert-success">
              <div class="flex flex-col">
                <span class="font-semibold">Password reset successful!</span>
                <span class="text-sm">You can now sign in with your new password.</span>
              </div>
            </div>

            <a href="/login" class="btn btn-primary w-full">
              Go to Sign In
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
