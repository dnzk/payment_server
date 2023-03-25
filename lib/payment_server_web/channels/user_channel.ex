defmodule PaymentServerWeb.UserChannel do
  @moduledoc """
  User channel
  """
  use Phoenix.Channel

  def join("user", _message, socket) do
    {:ok, socket}
  end
end
