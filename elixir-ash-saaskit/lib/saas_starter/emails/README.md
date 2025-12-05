# Email Functionality

This directory contains all email-related functionality for the SaaS Starter application.

## Overview

The email system uses **Swoosh** for sending emails and is configured to use the local mailbox adapter in development for easy testing and preview.

## Email Modules

### UserEmail (`lib/saas_starter/emails/user_email.ex`)

Handles all user-related emails:

- **`welcome_email(user)`** - Sends a welcome email to newly registered users
- **`password_reset_email(user, reset_token)`** - Sends password reset instructions with a secure token
- **`magic_link_email(user, magic_token)`** - Sends passwordless login link
- **`invite_email(invite, organization)`** - Sends team invitation emails

### InviteEmail (`lib/saas_starter/organizations/emails/invite_email.ex`)

Handles organization invitation emails:

- **`send_invite_email(invite, context)`** - Automatically sends invite emails when invites are created

## Configuration

### Development (Already Configured)

In `config/dev.exs`:
```elixir
config :saas_starter, SaasStarter.Mailer, adapter: Swoosh.Adapters.Local
```

The mailbox preview is available at: **http://localhost:4000/dev/mailbox**

### Production

In `config/runtime.exs`, configure your production email adapter:

```elixir
# Example with SendGrid
config :saas_starter, SaasStarter.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY")

# Example with Mailgun
config :saas_starter, SaasStarter.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")
```

## Usage Examples

### Sending Welcome Emails

After user registration (in your LiveView or controller):

```elixir
def handle_event("register", params, socket) do
  case Accounts.register_user(params) do
    {:ok, user} ->
      # Send welcome email
      UserEmail.welcome_email(user)
      |> Mailer.deliver()

      {:noreply, redirect(socket, to: ~p"/onboarding")}

    {:error, errors} ->
      {:noreply, assign(socket, :errors, errors)}
  end
end
```

### Password Reset (Automatic)

Password reset emails are **automatically sent** when users request a password reset. The `User` resource is configured to send emails via the `resettable` strategy:

```elixir
# In lib/saas_starter/accounts/user.ex (already configured)
resettable do
  sender fn user, token, _opts ->
    SaasStarter.Emails.UserEmail.password_reset_email(user, token)
    |> SaasStarter.Mailer.deliver()
  end
end
```

### Magic Link (Automatic)

Magic link emails are **automatically sent** when users request passwordless login. The `User` resource is configured to send emails via the `magic_link` strategy:

```elixir
# In lib/saas_starter/accounts/user.ex (already configured)
magic_link :magic_link do
  sender fn user, token, _opts ->
    SaasStarter.Emails.UserEmail.magic_link_email(user, token)
    |> SaasStarter.Mailer.deliver()
  end
end
```

### Team Invitations (Automatic)

Invitation emails are **automatically sent** when invites are created. The `Invite` resource has an `after_action` change that triggers email sending:

```elixir
# Creating an invite (email is sent automatically)
Organizations.create_invite(
  email: "newmember@example.com",
  role: :member,
  organization_id: org.id,
  actor: current_user,
  tenant: org.id
)
```

## Email Templates

All emails include:

- **Professional HTML design** with inline CSS for maximum email client compatibility
- **Plain text fallback** for email clients that don't support HTML
- **Responsive design** that works on mobile and desktop
- **Clear call-to-action buttons** with proper styling
- **Security considerations** (token expiry times, etc.)
- **Branded header and footer** with gradient backgrounds

### Email Styling

The emails use a consistent design system:

- **Welcome Email**: Purple gradient (#667eea to #764ba2)
- **Password Reset**: Orange-red gradient (#f97316 to #dc2626)
- **Magic Link**: Blue gradient (#06b6d4 to #3b82f6)
- **Invite Email**: Green gradient (#10b981 to #059669)

All emails use the same layout structure:
- Header with gradient background
- White content area with clear messaging
- CTA button matching the email theme
- Footer with copyright information

## Testing Emails in Development

1. **Start your Phoenix server**:
   ```bash
   mix phx.server
   ```

2. **Navigate to the mailbox preview**:
   ```
   http://localhost:4000/dev/mailbox
   ```

3. **Trigger an email action**:
   - Register a new user
   - Request a password reset
   - Request a magic link
   - Create an invite

4. **View the email in the mailbox**:
   - All emails will appear in the mailbox preview
   - You can see both HTML and text versions
   - Test the links and layout

## Customization

### Changing the From Address

Edit the module attributes in `user_email.ex`:

```elixir
@from_email "noreply@yourdomain.com"
@from_name "Your App Name"
```

### Changing Base URL

The base URL is used for generating links in emails. It's configured via application config:

```elixir
# In config/runtime.exs for production
config :saas_starter, :base_url, System.get_env("APP_URL", "https://yourdomain.com")
```

### Customizing Email Templates

The email HTML is defined inline in private functions. To customize:

1. Edit the `render_*_html/2` functions in `user_email.ex`
2. Modify the HTML structure and styling
3. Keep inline CSS for email client compatibility
4. Test in the `/dev/mailbox` preview

### Adding New Email Types

1. Add a new public function to `UserEmail`:
   ```elixir
   def new_feature_email(user, data) do
     new()
     |> to({user.full_name || user.email, user.email})
     |> from({@from_name, @from_email})
     |> subject("Subject Here")
     |> html_body(render_new_feature_html(user, data))
     |> text_body(render_new_feature_text(user, data))
   end
   ```

2. Add the HTML and text rendering functions
3. Call it where needed in your application

## Troubleshooting

### Emails not appearing in mailbox

- Check that `config :saas_starter, :dev_routes` is set to `true` in `config/dev.exs`
- Verify the Swoosh adapter is set to `Swoosh.Adapters.Local` in dev
- Check the Phoenix logs for any email delivery errors

### Emails not sending in production

- Verify your production email adapter is configured correctly
- Check that API keys are set in environment variables
- Review your email provider's documentation for rate limits and requirements
- Check application logs for detailed error messages

### Links not working in emails

- Verify the `:base_url` configuration is correct for your environment
- Check that the token parameters match what your routes expect
- Test the generated URLs manually

## Security Considerations

- **Tokens are single-use**: Password reset and magic link tokens are invalidated after use
- **Tokens expire**: Password reset tokens expire in 24 hours, magic links in 15 minutes
- **Invites expire**: Team invitations expire after 7 days
- **No sensitive data**: Emails don't contain passwords or other sensitive information
- **HTTPS in production**: Ensure all email links use HTTPS in production

## Future Enhancements

Consider adding:

- Email templates using a template engine (like HEEx templates)
- Email preview in tests
- Email analytics and tracking
- Transactional email logs
- Batch email sending for notifications
- Email preferences and unsubscribe functionality
