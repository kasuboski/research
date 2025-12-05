# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-12-05

### Upgraded - Major Dependency Updates

#### Language & Framework
- **Elixir**: 1.14 → 1.17+ (supports up to 1.19.3)
  - Enhanced type checking
  - Faster compilation (up to 4x in large projects)
  - Set-theoretic data types
- **Phoenix**: 1.7.14 → 1.7.19
  - Latest patches and bug fixes
- **Phoenix LiveView**: 0.20.17 → 1.1.18 ⚠️ **MAJOR VERSION**
  - Breaking changes addressed
  - Added `lazy_html` test dependency
  - Added `:phoenix_live_view` to compilers
  - Enabled `debug_attributes` in development

#### Ash Framework Ecosystem
- **Ash**: 3.4 → 3.10.0
  - 6 minor versions of improvements
  - Enhanced policy system
  - Query optimizations
- **AshPhoenix**: 2.1 → 2.3.18
  - Phoenix integration improvements
- **AshAuthentication**: 4.0 → 4.13.1
  - 13 minor versions of enhancements
  - Token handling improvements
  - Strategy updates
- **AshAuthenticationPhoenix**: 2.1 → 2.12.2
  - Enhanced Phoenix integration
- **AshPostgres**: 2.4 → 2.6.26
  - PostgreSQL data layer improvements

### Changed
- Updated `.tool-versions` to Elixir 1.19.3-otp-27
- Added `:phoenix_live_view` to project compilers in `mix.exs`
- Added `debug_attributes: true` to LiveView config in `config/dev.exs`
- Added `lazy_html` dependency for tests

### Migration Notes
- Fixed 3 syntax errors in LiveView files (nested case statements)
- All 49 source files validated with correct syntax
- All 8 test files validated with correct syntax
- All configuration files validated
- LiveView 1.1 compiler requirements met
- No breaking changes in application code required (except syntax fixes)
- Multi-tenancy and authentication architecture unchanged

### Validation Status
- ✅ **Syntax Validation**: All 49 source files + 8 test files validated
- ✅ **Configuration**: LiveView 1.1 requirements met
- ✅ **Documentation**: Updated to reflect new versions
- ⚠️ **Runtime Testing**: Requires proper Elixir environment for full validation

## [0.1.0] - 2025-12-04

### Added - Initial Release

#### Core Features
- Complete Ash-first architecture with domain-driven design
- Multi-tenant SaaS application structure
- Attribute-based multi-tenancy with organization isolation
- RBAC (Role-Based Access Control) with owner/member roles

#### Authentication System
- Email/password authentication via AshAuthentication
- Passwordless magic link authentication
- Password reset flow with secure tokens
- Session management with token-based auth
- Case-insensitive email handling (PostgreSQL citext)

#### Domain Models
- **Accounts Domain** (Global)
  - User resource with authentication
  - Token resource for session management
- **Organizations Domain** (Tenanted)
  - Organization resource with URL-friendly slugs
  - Membership resource with RBAC
  - Invite resource with secure tokens and expiration

#### User Flows
- User registration and onboarding
- Organization creation (first-time setup)
- Team member invitation and acceptance
- Organization switching
- User profile and security settings
- Dashboard with team overview

#### UI & Components
- Phoenix LiveView for interactive UI
- Tailwind CSS + DaisyUI component library
- 650+ lines of reusable core components
- Responsive layouts with mobile support
- Professional email templates

#### Email System
- Swoosh integration with 4 email types:
  - Welcome emails
  - Password reset emails
  - Magic link emails
  - Team invitation emails
- Dev mailbox preview at `/dev/mailbox`
- HTML templates with inline CSS
- Plain text fallbacks

#### Security
- Policy-based authorization at resource level
- Multi-tenancy isolation preventing cross-tenant access
- Last owner protection
- CSRF protection
- SQL injection prevention (Ecto parameterization)
- XSS prevention (Phoenix HTML escaping)
- Secure password hashing (Argon2)

#### Database
- PostgreSQL with UUID primary keys
- Comprehensive migrations for all resources
- Proper indexes for multi-tenant performance
- Foreign key constraints
- Required extensions (uuid-ossp, citext, ash-functions)

#### Testing
- 85+ automated tests across all domains
- Domain tests for resources, actions, and policies
- Integration tests for workflows
- Multi-tenancy isolation tests
- RBAC permission tests

#### Documentation
- README.md with complete setup instructions
- CLAUDE.md with architecture patterns and guidelines
- TESTING.md with comprehensive testing guide
- Inline code documentation

[Unreleased]: https://github.com/yourusername/elixir-ash-saaskit/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/yourusername/elixir-ash-saaskit/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yourusername/elixir-ash-saaskit/releases/tag/v0.1.0
