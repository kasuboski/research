defmodule SaasStarter.Accounts.Checks.IsSelf do
  @moduledoc """
  Policy check that verifies the actor is the same as the resource being accessed.
  Used to ensure users can only access/modify their own records.
  """
  use Ash.Policy.Check

  @impl true
  def describe(_options) do
    "actor is the resource being accessed"
  end

  @impl true
  def match?(_actor, %{data: nil}, _opts), do: false
  def match?(_actor, %{data: []}, _opts), do: false

  def match?(nil, _context, _opts), do: false

  def match?(actor, %{data: data}, _opts) when is_list(data) do
    Enum.all?(data, fn record -> record.id == actor.id end)
  end

  def match?(actor, %{data: record}, _opts) do
    record.id == actor.id
  end
end
