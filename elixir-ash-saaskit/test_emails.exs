#!/usr/bin/env elixir

# Email Functionality Test Script
# Run this in IEx to test email functionality
#
# Usage:
#   mix run test_emails.exs
#   OR in IEx:
#   iex> import_file("test_emails.exs")

alias SaasStarter.Emails.UserEmail
alias SaasStarter.Mailer

IO.puts("\n=== Email Functionality Test Script ===\n")

# Test user data
test_user = %{
  email: "test@example.com",
  full_name: "Test User"
}

test_invite = %{
  email: "invite@example.com",
  role: :member,
  token: "test-invite-token-123"
}

test_org = %{
  name: "Acme Corporation"
}

IO.puts("1. Testing Welcome Email...")
try do
  UserEmail.welcome_email(test_user)
  |> Mailer.deliver()

  IO.puts("   ✅ Welcome email sent successfully")
rescue
  e -> IO.puts("   ❌ Error: #{inspect(e)}")
end

IO.puts("\n2. Testing Password Reset Email...")
try do
  UserEmail.password_reset_email(test_user, "test-reset-token-456")
  |> Mailer.deliver()

  IO.puts("   ✅ Password reset email sent successfully")
rescue
  e -> IO.puts("   ❌ Error: #{inspect(e)}")
end

IO.puts("\n3. Testing Magic Link Email...")
try do
  UserEmail.magic_link_email(test_user, "test-magic-token-789")
  |> Mailer.deliver()

  IO.puts("   ✅ Magic link email sent successfully")
rescue
  e -> IO.puts("   ❌ Error: #{inspect(e)}")
end

IO.puts("\n4. Testing Team Invite Email...")
try do
  UserEmail.invite_email(test_invite, test_org)
  |> Mailer.deliver()

  IO.puts("   ✅ Team invite email sent successfully")
rescue
  e -> IO.puts("   ❌ Error: #{inspect(e)}")
end

IO.puts("\n=== Test Complete ===")
IO.puts("\nView all test emails at: http://localhost:4000/dev/mailbox\n")
IO.puts("Note: Make sure Phoenix server is running (mix phx.server)")
IO.puts("")
