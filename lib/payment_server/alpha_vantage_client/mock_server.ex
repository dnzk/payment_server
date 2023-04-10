defmodule PaymentServer.AlphaVantageClient.MockServer do
  @moduledoc """
  Alpha vantage mock server
  """
  use GenServer
  alias PaymentServer.AlphaVantageClient.MockController

  def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    Plug.Cowboy.http(MockController, [], port: 8081)
  end
end
