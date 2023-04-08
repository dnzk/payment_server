defmodule PaymentServerWeb.ChannelCase do
  @moduledoc """
  Channel case
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest

      @endpoint PaymentServerWeb.Endpoint
    end
  end
end
