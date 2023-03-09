defmodule PaymentServer.AlphaVantageClient.MockServer do
  use GenServer
  alias PaymentServer.AlphaVantageClient.MockController

  def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    Plug.Cowboy.http(MockController, [], port: 8081)
  end
end
