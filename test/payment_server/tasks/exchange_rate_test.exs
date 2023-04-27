defmodule PaymentServer.Tasks.ExchangeRateTest do
  @moduledoc """
  ExchangeRate test
  """

  use ExUnit.Case
  alias PaymentServer.Tasks.ExchangeRate

  describe "&request_exchange_rate/1" do
    test "sends request to alpha vantage API with proper query formatting" do
      from = "USD"
      to = "JPY"

      response =
        %{from: from, to: to}
        |> ExchangeRate.request_exchange_rate()
        |> Task.await()

      assert {:ok, %{request: %{url: url}}} = response

      assert String.contains?(
               url,
               "query?function=CURRENCY_EXCHANGE_RATE&from_currency=#{from}&to_currency=#{to}"
             )
    end
  end

  describe "&get_exchange_rate/1" do
    test "parses request body" do
      rate_response =
        %{from: "USD", to: "JPY"}
        |> ExchangeRate.request_exchange_rate()
        |> ExchangeRate.get_exchange_rate_response()
        |> ExchangeRate.get_exchange_rate()

      assert {:ok, rate} = rate_response
      assert is_float(rate)
    end
  end
end
