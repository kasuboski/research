defmodule SaasStarterWeb.LiveComponents do
  @moduledoc """
  Provides reusable LiveView components.
  """
  use Phoenix.Component

  @doc """
  Renders a live title component.
  """
  attr :suffix, :string, default: nil
  slot :inner_block, required: true

  def live_title(assigns) do
    ~H"""
    <title>
      <%= render_slot(@inner_block) %><%= if @suffix, do: @suffix %>
    </title>
    """
  end
end
