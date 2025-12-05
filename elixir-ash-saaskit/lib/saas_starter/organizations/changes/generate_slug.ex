defmodule SaasStarter.Organizations.Changes.GenerateSlug do
  @moduledoc """
  Change module that generates a URL-friendly slug from the organization name.

  The slug is:
  - Lowercase
  - Alphanumeric with hyphens
  - Unique across all organizations
  - Auto-generated from the name if not provided

  Examples:
  - "My Company" -> "my-company"
  - "Acme Corp!" -> "acme-corp"
  - "Test 123" -> "test-123"
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    # Only generate if slug is not already set
    case Ash.Changeset.get_attribute(changeset, :slug) do
      nil ->
        # Get the name from the changeset
        case Ash.Changeset.get_attribute(changeset, :name) do
          nil ->
            changeset

          name ->
            slug = generate_slug(name)
            Ash.Changeset.force_change_attribute(changeset, :slug, slug)
        end

      _slug ->
        # Slug already provided, just ensure it's properly formatted
        slug = Ash.Changeset.get_attribute(changeset, :slug)
        formatted_slug = format_slug(slug)
        Ash.Changeset.force_change_attribute(changeset, :slug, formatted_slug)
    end
  end

  defp generate_slug(name) do
    format_slug(name)
  end

  defp format_slug(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
