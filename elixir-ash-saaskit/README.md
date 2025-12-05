# SaasStarter

A modern SaaS starter kit built with Elixir, Phoenix Framework, and Ash Framework.

## Features

- **Phoenix Framework 1.7.19**: Latest Phoenix with LiveView for real-time, interactive experiences
- **Ash Framework 3.10**: Declarative resource modeling with powerful abstractions
- **Authentication**: Built-in authentication with AshAuthentication 4.13
- **Database**: PostgreSQL with AshPostgres 2.6
- **UI**: Tailwind CSS with DaisyUI components
- **Email**: Swoosh for sending emails with local preview in development
- **Testing**: Comprehensive test setup with ExUnit

## Tech Stack

- Elixir ~> 1.17 (tested with 1.19.3)
- Phoenix ~> 1.7.19
- Phoenix LiveView ~> 1.1
- Ash ~> 3.10
- AshAuthentication ~> 4.13
- AshPostgres ~> 2.6
- PostgreSQL (via AshPostgres)
- Tailwind CSS
- DaisyUI

## Prerequisites

Before you begin, ensure you have the following installed:

- Elixir 1.17 or later (1.19.3 recommended)
- Erlang/OTP 27 or later
- PostgreSQL 14 or later
- Node.js 18 or later (for asset compilation)

## Getting Started

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd elixir-ash-saaskit
```

### 2. Install dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies for assets
cd assets && npm install && cd ..
```

### 3. Set up the database

Make sure PostgreSQL is running, then:

```bash
# Create and migrate the database
mix ash.setup
```

This will:
- Create the development database
- Install required PostgreSQL extensions (uuid-ossp, citext, ash-functions)
- Run migrations

### 4. Start the Phoenix server

```bash
mix phx.server
```

Or inside IEx:

```bash
iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Development

### Available Mix Tasks

```bash
# Setup the project (install deps, setup DB, compile assets)
mix setup

# Reset the database
mix ash.reset

# Run tests
mix test

# Check code formatting
mix format --check-formatted

# Format code
mix format

# Build assets for production
mix assets.deploy
```

### Asset Development

Assets are compiled automatically in development mode. The following watchers are configured:

- **Tailwind CSS**: Watches and compiles CSS files
- **esbuild**: Bundles JavaScript files

### Email Preview

In development, all sent emails can be previewed at:
[`localhost:4000/dev/mailbox`](http://localhost:4000/dev/mailbox)

### LiveDashboard

Phoenix LiveDashboard is available in development at:
[`localhost:4000/dev/dashboard`](http://localhost:4000/dev/dashboard)

## Project Structure

```
├── assets/              # Frontend assets (JS, CSS)
│   ├── css/            # Stylesheets
│   ├── js/             # JavaScript files
│   └── vendor/         # Third-party JS libraries
├── config/             # Application configuration
│   ├── config.exs      # Base configuration
│   ├── dev.exs         # Development configuration
│   ├── test.exs        # Test configuration
│   └── runtime.exs     # Runtime configuration
├── lib/
│   ├── saas_starter/           # Business logic layer
│   │   ├── application.ex      # Application supervisor
│   │   └── repo.ex             # Database repository
│   └── saas_starter_web/       # Web layer
│       ├── components/         # Reusable components
│       ├── controllers/        # Phoenix controllers
│       ├── endpoint.ex         # Phoenix endpoint
│       ├── router.ex           # Application router
│       └── telemetry.ex        # Telemetry setup
├── priv/
│   ├── gettext/        # Internationalization files
│   ├── repo/           # Database migrations and seeds
│   └── static/         # Static assets (generated)
└── test/               # Test files
```

## Authentication

The project uses AshAuthentication for user authentication. It provides:

- User registration
- Email/password sign-in
- Password reset functionality
- Session management

## Configuration

### Database

Update your database credentials in `config/dev.exs`:

```elixir
config :saas_starter, SaasStarter.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "saas_starter_dev"
```

### Email

In development, emails are captured by Swoosh's local adapter. For production, configure your email adapter in `config/runtime.exs`.

## Deployment

### Preparing for Production

1. Set required environment variables:
   - `DATABASE_URL`: PostgreSQL connection URL
   - `SECRET_KEY_BASE`: Generate with `mix phx.gen.secret`
   - `PHX_HOST`: Your production domain

2. Build assets:
```bash
mix assets.deploy
```

3. Build a release:
```bash
MIX_ENV=prod mix release
```

### Running in Production

```bash
PHX_SERVER=true _build/prod/rel/saas_starter/bin/saas_starter start
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Learn More

- Phoenix Framework: https://www.phoenixframework.org/
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view/
- Ash Framework: https://ash-hq.org/
- Elixir: https://elixir-lang.org/
- Tailwind CSS: https://tailwindcss.com/
- DaisyUI: https://daisyui.com/
