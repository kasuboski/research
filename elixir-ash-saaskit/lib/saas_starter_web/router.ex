defmodule SaasStarterWeb.Router do
  use SaasStarterWeb, :router

  import AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SaasStarterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  pipeline :require_authenticated_user do
    plug :load_from_session
  end

  pipeline :require_organization do
    plug SaasStarterWeb.Plugs.RequireOrganization
  end

  pipeline :load_tenant do
    plug SaasStarterWeb.Plugs.LoadTenant
  end

  # Public routes (no authentication required)
  scope "/", SaasStarterWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Authentication routes
    auth_routes AuthController, SaasStarter.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Reset password route
    reset_route []

    # Custom authentication LiveViews
    live "/register", Auth.RegisterLive, :index
    live "/login", Auth.LoginLive, :index
    live "/magic-link", Auth.MagicLinkLive, :index
    live "/forgot-password", Auth.ForgotPasswordLive, :index
    live "/reset-password/:token", Auth.ResetPasswordLive, :index

    # Public invite acceptance (can be accessed by non-authenticated users)
    live "/invites/:token", Team.AcceptInviteLive, :index
  end

  # Authenticated routes (require login, no organization required)
  scope "/", SaasStarterWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Onboarding - shown when user has no organizations
    live "/onboarding/create-organization", Onboarding.CreateOrganizationLive, :index

    # Settings (not organization-specific)
    live "/settings/profile", Settings.ProfileLive, :index
    live "/settings/security", Settings.SecurityLive, :index

    # Dashboard redirect - will redirect to first organization or onboarding
    live "/dashboard", Dashboard.RedirectLive, :index
  end

  # Tenanted routes (require authentication AND organization context)
  scope "/:org_slug", SaasStarterWeb do
    pipe_through [:browser, :require_authenticated_user, :require_organization, :load_tenant]

    # Organization dashboard
    live "/dashboard", Dashboard.IndexLive, :index

    # Team management
    live "/team", Team.IndexLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", SaasStarterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:saas_starter, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SaasStarterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
