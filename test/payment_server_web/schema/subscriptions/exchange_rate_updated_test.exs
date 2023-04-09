defmodule PaymentServerWeb.Schema.Subscriptions.ExchangeRateUpdatedTest do
  @moduledoc """
  Exchange rate updated test
  """
  use PaymentServerWeb.SubscriptionCase
  use PaymentServer.DataCase

  @exchange_rate_updated_document """
  subscription ExchangeRateUpdated($fromCurrency:String!, $toCurrency:String!) {
    exchangeRateUpdated(fromCurrency:$fromCurrency, toCurrency:$toCurrency) {
      fromCurrency
      toCurrency
      exchangeRate
    }
  }
  """

  describe "@exchange_rate_updated" do
    test "sends when exchange rate updates", %{socket: socket} do
      ref =
        push_doc(socket, @exchange_rate_updated_document,
          variables: %{
            "fromCurrency" => "USD",
            "toCurrency" => "CAD"
          }
        )

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      expected = %{
        result: %{
          data: %{
            "exchangeRateUpdated" => %{
              "exchangeRate" => 0.89,
              "fromCurrency" => "USD",
              "toCurrency" => "CAD"
            }
          }
        },
        subscriptionId: subscription_id
      }

      assert_push "subscription:data", push, 1100
      assert expected == push
    end
  end
end
