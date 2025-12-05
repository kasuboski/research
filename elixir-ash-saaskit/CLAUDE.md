# CLAUDE.md - Ash Phoenix SaaS Starter Kit

## Project Overview
Production-ready SaaS starter kit built with Elixir, Phoenix LiveView, and Ash Framework.
**Architecture principle**: "Model your domain, derive the rest."

## Core Architecture

### Ash-First Approach
- **Resources are source of truth**: All schema, validations, and policies in Ash Resources
- **Actions are interface**: ALL business logic through Ash Actions (never raw Ecto)
- **Policies enforce security**: Authorization at resource level, not UI

### Domain Structure
```
Accounts (Global)          Organizations (Tenanted)
├── User                   ├── Organization
└── Token                  ├── Membership (RBAC)
                          └── Invite
```

### Thin Phoenix Layer
- LiveViews handle ONLY: HTTP, WebSocket, UI rendering
- NO business logic in LiveViews
- NO direct Ecto queries
- Delegate ALL operations to Ash Actions

### Multi-Tenancy
- **Strategy**: Attribute-based (`organization_id`)
- **Isolation**: Automatic filtering via Ash policies
- **Resolution**: URL-based (`/org-slug/dashboard`)

## Key Patterns

### Authentication (AshAuthentication)
```elixir
authentication do
  strategies do
    password :password do
      identity_field :email
      hashed_password_field :hashed_password
    end
  end

  tokens do
    enabled? true
    token_resource SaasStarter.Accounts.Token
    signing_secret fn _, _ ->
      Application.fetch_env!(:saas_starter, :token_signing_secret)
    end
  end
end
```

### Multi-Tenancy Configuration
```elixir
# Tenanted resource
multitenancy do
  strategy :attribute
  attribute :organization_id
  global? false
end

# Always pass tenant in operations
Organizations.list_memberships!(
  actor: current_user,
  tenant: current_organization.id
)
```

### Policy Authorization
```elixir
policies do
  policy action_type(:read) do
    authorize_if relates_to_actor_via(:memberships)
  end

  policy action_type([:update, :destroy]) do
    authorize_if IsOwner
  end
end
```

### Tenant Resolution
```elixir
# LoadTenant plug
def call(conn, _opts) do
  org_slug = conn.path_params["org_slug"]
  org = Organizations.get_by_slug!(org_slug, actor: conn.assigns.current_user)

  conn
  |> assign(:current_organization, org)
  |> assign(:tenant, org.id)
end
```

## Common Pitfalls

### ❌ DON'T: Direct Database Access
```elixir
Repo.insert!(%User{email: email})  # WRONG
```

### ✅ DO: Use Ash Actions
```elixir
Accounts.register_user(%{email: email, password: password})  # CORRECT
```

### ❌ DON'T: Business Logic in LiveViews
```elixir
# WRONG
def handle_event("create_org", params, socket) do
  org = Repo.insert!(%Organization{name: params["name"]})
  membership = Repo.insert!(%Membership{...})
end
```

### ✅ DO: Delegate to Domain
```elixir
# CORRECT
def handle_event("create_org", params, socket) do
  case Organizations.create_organization_with_owner(params, actor: socket.assigns.current_user) do
    {:ok, org} -> {:noreply, redirect(socket, to: ~p"/#{org.slug}/dashboard")}
    {:error, errors} -> {:noreply, assign(socket, :errors, errors)}
  end
end
```

### ❌ DON'T: Forget Tenant Context
```elixir
# WRONG - Data leak!
Organizations.list_memberships!(actor: current_user)
```

### ✅ DO: Always Pass Tenant
```elixir
# CORRECT
Organizations.list_memberships!(actor: current_user, tenant: org.id)
```

## Development Workflow

1. **Add feature**: Start with Resource (schema + policies)
2. **Add actions**: Define business logic as Ash Actions
3. **Add UI**: Create LiveView that calls the action
4. **Add tests**: Test Resource, then flow

## Testing Strategy

**Domain tests (priority)**: Ash Resources in isolation
- Validations, policies, actions, multi-tenancy isolation

**Integration tests**: LiveView flows (happy paths)
- Registration → Onboarding → Dashboard
- Login → Context switching
- Invite → Accept → Membership

## Environment Setup

```bash
# Required environment variables
DATABASE_URL=postgres://localhost/saas_starter_dev
SECRET_KEY_BASE=<mix phx.gen.secret>
TOKEN_SIGNING_SECRET=<mix phx.gen.secret>

# Setup commands
mix deps.get
mix ash.setup
mix phx.server

# Dev mailbox
http://localhost:4000/dev/mailbox
```

## Key Dependencies
- Phoenix 1.7 + LiveView 0.20
- Ash 3.0 + AshPhoenix 2.0
- AshAuthentication 4.0
- AshPostgres 2.0
- Swoosh 1.14
- Tailwind + DaisyUI
