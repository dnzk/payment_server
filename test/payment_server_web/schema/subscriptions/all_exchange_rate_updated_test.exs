defmodule PaymentServerWeb.Schema.Subscriptions.AllExchangeRateUpdatedTest do
  @moduledoc """
  All exchange rate updated test
  """
  use PaymentServerWeb.SubscriptionCase
  use PaymentServer.DataCase

  @all_exchange_rate_updated_document """
  subscription AllExchangeRateUpdated {
    allExchangeRateUpdated {
      fromCurrency
      toCurrency
      exchangeRate
    }
  }
  """

  describe "@all_exchange_rate_updated" do
    test "sends when any exchange rate updates", %{socket: socket} do
      ref = push_doc(socket, @all_exchange_rate_updated_document)

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      assert_push "subscription:data", push, 1100

      assert %{
               result: %{
                 data: %{
                   "allExchangeRateUpdated" => %{
                     "exchangeRate" => 0.89
                   }
                 }
               },
               subscriptionId: ^subscription_id
             } = push
    end
  end
end
