defmodule PaymentServer.ExchangeRateSubscriptionServerTest do
  @moduledoc """
  Exchange rate subscription server test
  """

  use ExUnit.Case
  use PaymentServer.DataCase
  alias PaymentServer.ExchangeRateSubscriptionServer

  setup do
    ExchangeRateSubscriptionServer.start_link([])
    ExchangeRateSubscriptionServer.reset()
    :ok
  end

  describe "&request_exchange_rate/2" do
    test "adds supplied key into state" do
      s = :sys.get_state(ExchangeRateSubscriptionServer)
      assert %{} === s

      ExchangeRateSubscriptionServer.request_exchange_rate(%{from: "USD", to: "JPY"})
      s = :sys.get_state(ExchangeRateSubscriptionServer)
      assert Map.fetch!(s, "USD/JPY") === nil
    end
  end

  describe "&request_all_exchange_rate/1" do
    test "adds all existing currency pairs into state" do
      s = :sys.get_state(ExchangeRateSubscriptionServer)
      assert %{} === s

      ExchangeRateSubscriptionServer.request_all_exchange_rate()
      s = :sys.get_state(ExchangeRateSubscriptionServer)

      assert %{"EUR/USD" => nil, "USD/EUR" => nil} === s
    end
  end

  describe "&get_latest_exchange_rate/1" do
    test "returns cached exchange rate by key" do
      ExchangeRateSubscriptionServer.request_exchange_rate(%{from: "USD", to: "IDR"})
      assert {:ok, nil} = ExchangeRateSubscriptionServer.get_latest_exchange_rate("USD/IDR")
    end
  end

  describe "&update_exchange_rate/2" do
    test "upserts exchange rate by key" do
      ExchangeRateSubscriptionServer.request_all_exchange_rate()
      assert {:ok, nil} = ExchangeRateSubscriptionServer.get_latest_exchange_rate("EUR/USD")

      ExchangeRateSubscriptionServer.update_exchange_rate("EUR/USD", 0.98)
      assert {:ok, 0.98} = ExchangeRateSubscriptionServer.get_latest_exchange_rate("EUR/USD")
    end
  end
end
