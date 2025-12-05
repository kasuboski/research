defmodule SaasStarter.Emails.UserEmail do
  @moduledoc """
  Email templates for user-related communications.

  This module provides email functions for:
  - Welcome emails for new users
  - Password reset emails with secure tokens
  - Magic link emails for passwordless authentication
  - Team invitation emails
  """

  import Swoosh.Email
  alias SaasStarterWeb.Layouts.EmailHTML

  @from_email "noreply@saas-starter.com"
  @from_name "SaaS Starter"

  @doc """
  Sends a welcome email to a newly registered user.

  ## Parameters
    - user: The user struct containing email and full_name

  ## Example
      iex> user = %{email: "user@example.com", full_name: "John Doe"}
      iex> welcome_email(user)
  """
  def welcome_email(user) do
    new()
    |> to({user.full_name || user.email, user.email})
    |> from({@from_name, @from_email})
    |> subject("Welcome to SaaS Starter!")
    |> html_body(render_welcome_html(user))
    |> text_body(render_welcome_text(user))
  end

  @doc """
  Sends a password reset email with a secure token.

  ## Parameters
    - user: The user struct containing email and full_name
    - reset_token: The secure password reset token

  ## Example
      iex> user = %{email: "user@example.com", full_name: "John Doe"}
      iex> password_reset_email(user, "secure_token_123")
  """
  def password_reset_email(user, reset_token) do
    reset_url = build_reset_url(reset_token)

    new()
    |> to({user.full_name || user.email, user.email})
    |> from({@from_name, @from_email})
    |> subject("Reset your password")
    |> html_body(render_password_reset_html(user, reset_url))
    |> text_body(render_password_reset_text(user, reset_url))
  end

  @doc """
  Sends a magic link email for passwordless authentication.

  ## Parameters
    - user: The user struct containing email and full_name
    - magic_token: The secure magic link token

  ## Example
      iex> user = %{email: "user@example.com", full_name: "John Doe"}
      iex> magic_link_email(user, "magic_token_456")
  """
  def magic_link_email(user, magic_token) do
    magic_url = build_magic_link_url(magic_token)

    new()
    |> to({user.full_name || user.email, user.email})
    |> from({@from_name, @from_email})
    |> subject("Sign in to SaaS Starter")
    |> html_body(render_magic_link_html(user, magic_url))
    |> text_body(render_magic_link_text(user, magic_url))
  end

  @doc """
  Sends a team invitation email.

  ## Parameters
    - invite: The invite struct containing email and role
    - organization: The organization struct containing name

  ## Example
      iex> invite = %{email: "newmember@example.com", role: :member, token: "invite_token"}
      iex> organization = %{name: "Acme Corp"}
      iex> invite_email(invite, organization)
  """
  def invite_email(invite, organization) do
    invite_url = build_invite_url(invite.token)

    new()
    |> to(invite.email)
    |> from({@from_name, @from_email})
    |> subject("You've been invited to join #{organization.name}")
    |> html_body(render_invite_html(invite, organization, invite_url))
    |> text_body(render_invite_text(invite, organization, invite_url))
  end

  # Private helper functions for building URLs

  defp build_reset_url(token) do
    base_url = get_base_url()
    "#{base_url}/auth/password-reset?token=#{token}"
  end

  defp build_magic_link_url(token) do
    base_url = get_base_url()
    "#{base_url}/auth/magic-link?token=#{token}"
  end

  defp build_invite_url(token) do
    base_url = get_base_url()
    "#{base_url}/auth/accept-invite?token=#{token}"
  end

  defp get_base_url do
    # In production, this should come from environment config
    Application.get_env(:saas_starter, :base_url, "http://localhost:4000")
  end

  # HTML rendering functions

  defp render_welcome_html(user) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to SaaS Starter</title>
      </head>
      <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f5; padding: 40px 20px;">
          <tr>
            <td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <!-- Header -->
                <tr>
                  <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px 8px 0 0;">
                    <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">Welcome to SaaS Starter</h1>
                  </td>
                </tr>
                <!-- Content -->
                <tr>
                  <td style="padding: 40px;">
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Hi #{user.full_name || "there"},
                    </p>
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Welcome to SaaS Starter! We're excited to have you on board.
                    </p>
                    <p style="margin: 0 0 30px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Your account has been successfully created. You can now create your first organization and start inviting team members.
                    </p>
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="center">
                          <a href="#{get_base_url()}/dashboard" style="display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;">
                            Get Started
                          </a>
                        </td>
                      </tr>
                    </table>
                    <p style="margin: 30px 0 0; color: #71717a; font-size: 14px; line-height: 1.6;">
                      If you have any questions, feel free to reply to this email. We're here to help!
                    </p>
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding: 30px 40px; background-color: #fafafa; border-radius: 0 0 8px 8px; text-align: center;">
                    <p style="margin: 0; color: #a1a1aa; font-size: 12px;">
                      &copy; 2024 SaaS Starter. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  defp render_password_reset_html(user, reset_url) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reset Your Password</title>
      </head>
      <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f5; padding: 40px 20px;">
          <tr>
            <td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <!-- Header -->
                <tr>
                  <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #f97316 0%, #dc2626 100%); border-radius: 8px 8px 0 0;">
                    <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">Reset Your Password</h1>
                  </td>
                </tr>
                <!-- Content -->
                <tr>
                  <td style="padding: 40px;">
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Hi #{user.full_name || "there"},
                    </p>
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      We received a request to reset the password for your SaaS Starter account.
                    </p>
                    <p style="margin: 0 0 30px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Click the button below to choose a new password. This link will expire in 24 hours.
                    </p>
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="center">
                          <a href="#{reset_url}" style="display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #f97316 0%, #dc2626 100%); color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;">
                            Reset Password
                          </a>
                        </td>
                      </tr>
                    </table>
                    <p style="margin: 30px 0 0; color: #71717a; font-size: 14px; line-height: 1.6;">
                      If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.
                    </p>
                    <p style="margin: 20px 0 0; color: #a1a1aa; font-size: 12px; line-height: 1.6;">
                      If the button doesn't work, copy and paste this link into your browser:<br>
                      <span style="word-break: break-all;">#{reset_url}</span>
                    </p>
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding: 30px 40px; background-color: #fafafa; border-radius: 0 0 8px 8px; text-align: center;">
                    <p style="margin: 0; color: #a1a1aa; font-size: 12px;">
                      &copy; 2024 SaaS Starter. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  defp render_magic_link_html(user, magic_url) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sign In to SaaS Starter</title>
      </head>
      <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f5; padding: 40px 20px;">
          <tr>
            <td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <!-- Header -->
                <tr>
                  <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%); border-radius: 8px 8px 0 0;">
                    <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">Sign In to Your Account</h1>
                  </td>
                </tr>
                <!-- Content -->
                <tr>
                  <td style="padding: 40px;">
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Hi #{user.full_name || "there"},
                    </p>
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Click the button below to sign in to your SaaS Starter account. No password needed!
                    </p>
                    <p style="margin: 0 0 30px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      This link will expire in 15 minutes for security purposes.
                    </p>
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="center">
                          <a href="#{magic_url}" style="display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%); color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;">
                            Sign In Now
                          </a>
                        </td>
                      </tr>
                    </table>
                    <p style="margin: 30px 0 0; color: #71717a; font-size: 14px; line-height: 1.6;">
                      If you didn't request this sign-in link, you can safely ignore this email.
                    </p>
                    <p style="margin: 20px 0 0; color: #a1a1aa; font-size: 12px; line-height: 1.6;">
                      If the button doesn't work, copy and paste this link into your browser:<br>
                      <span style="word-break: break-all;">#{magic_url}</span>
                    </p>
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding: 30px 40px; background-color: #fafafa; border-radius: 0 0 8px 8px; text-align: center;">
                    <p style="margin: 0; color: #a1a1aa; font-size: 12px;">
                      &copy; 2024 SaaS Starter. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  defp render_invite_html(invite, organization, invite_url) do
    role_text = if invite.role == :owner, do: "owner", else: "member"

    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>You've Been Invited</title>
      </head>
      <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f5; padding: 40px 20px;">
          <tr>
            <td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <!-- Header -->
                <tr>
                  <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #10b981 0%, #059669 100%); border-radius: 8px 8px 0 0;">
                    <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">You've Been Invited!</h1>
                  </td>
                </tr>
                <!-- Content -->
                <tr>
                  <td style="padding: 40px;">
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Hello,
                    </p>
                    <p style="margin: 0 0 20px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      You've been invited to join <strong>#{organization.name}</strong> on SaaS Starter as a <strong>#{role_text}</strong>.
                    </p>
                    <p style="margin: 0 0 30px; color: #3f3f46; font-size: 16px; line-height: 1.6;">
                      Click the button below to accept the invitation and get started with your team.
                    </p>
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="center">
                          <a href="#{invite_url}" style="display: inline-block; padding: 14px 32px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;">
                            Accept Invitation
                          </a>
                        </td>
                      </tr>
                    </table>
                    <p style="margin: 30px 0 0; color: #71717a; font-size: 14px; line-height: 1.6;">
                      This invitation will expire in 7 days. If you don't want to join, you can safely ignore this email.
                    </p>
                    <p style="margin: 20px 0 0; color: #a1a1aa; font-size: 12px; line-height: 1.6;">
                      If the button doesn't work, copy and paste this link into your browser:<br>
                      <span style="word-break: break-all;">#{invite_url}</span>
                    </p>
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding: 30px 40px; background-color: #fafafa; border-radius: 0 0 8px 8px; text-align: center;">
                    <p style="margin: 0; color: #a1a1aa; font-size: 12px;">
                      &copy; 2024 SaaS Starter. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  # Plain text rendering functions

  defp render_welcome_text(user) do
    """
    Welcome to SaaS Starter!

    Hi #{user.full_name || "there"},

    Welcome to SaaS Starter! We're excited to have you on board.

    Your account has been successfully created. You can now create your first organization and start inviting team members.

    Get started: #{get_base_url()}/dashboard

    If you have any questions, feel free to reply to this email. We're here to help!

    ---
    © 2024 SaaS Starter. All rights reserved.
    """
  end

  defp render_password_reset_text(user, reset_url) do
    """
    Reset Your Password

    Hi #{user.full_name || "there"},

    We received a request to reset the password for your SaaS Starter account.

    Click the link below to choose a new password. This link will expire in 24 hours.

    #{reset_url}

    If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.

    ---
    © 2024 SaaS Starter. All rights reserved.
    """
  end

  defp render_magic_link_text(user, magic_url) do
    """
    Sign In to Your Account

    Hi #{user.full_name || "there"},

    Click the link below to sign in to your SaaS Starter account. No password needed!

    #{magic_url}

    This link will expire in 15 minutes for security purposes.

    If you didn't request this sign-in link, you can safely ignore this email.

    ---
    © 2024 SaaS Starter. All rights reserved.
    """
  end

  defp render_invite_text(invite, organization, invite_url) do
    role_text = if invite.role == :owner, do: "owner", else: "member"

    """
    You've Been Invited!

    Hello,

    You've been invited to join #{organization.name} on SaaS Starter as a #{role_text}.

    Click the link below to accept the invitation and get started with your team:

    #{invite_url}

    This invitation will expire in 7 days. If you don't want to join, you can safely ignore this email.

    ---
    © 2024 SaaS Starter. All rights reserved.
    """
  end
end
