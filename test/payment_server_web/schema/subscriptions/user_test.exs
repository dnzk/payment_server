defmodule PaymentServerWeb.Schema.Subscriptions.UserTest do
  @moduledoc """
  Subscriptions test
  """
  use PaymentServerWeb.SubscriptionCase, async: true
  use PaymentServer.DataCase

  @total_worth_changed_document """
  subscription TotalWorthChanged($userId: Int!, $currency: String!){
    totalWorthChanged(userId:$userId, currency:$currency) {
      value
      currency
    }
  }
  """
  @create_wallet_document """
  mutation CreateWallet($userId: Int!, $value: Int!, $currency: String!) {
    createWallet(userId: $userId, value: $value, currency: $currency) {
      id
      value
      currency
    }
  }
  """
  @send_money_document """
  mutation SendMoney($recipientAccountNumber: Int!, $senderAccountNumber:Int!, $value:Int!) {
    sendMoney(recipientAccountNumber:$recipientAccountNumber, senderAccountNumber:$senderAccountNumber, value:$value) {
      recipient {
        value
      }
      sender {
        value
      }
    }
  }
  """

  describe "@total_worth_changed" do
    test "sends with send money", %{socket: socket} do
      ref =
        push_doc(socket, @total_worth_changed_document,
          variables: %{"userId" => 1, "currency" => "USD"}
        )

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      ref =
        push_doc(socket, @send_money_document,
          variables: %{
            "senderAccountNumber" => 123_456,
            "recipientAccountNumber" => 333_222,
            "value" => 5000
          }
        )

      assert_reply ref, :ok, reply

      assert %{
               data: %{
                 "sendMoney" => %{
                   "recipient" => %{
                     "value" => 1_295_000
                   },
                   "sender" => %{
                     "value" => 995_000
                   }
                 }
               }
             } = reply

      expected = %{
        result: %{
          data: %{
            "totalWorthChanged" => %{
              "currency" => "USD",
              "value" => 45_495_000
            }
          }
        },
        subscriptionId: subscription_id
      }

      assert_push "subscription:data", push
      assert expected == push
    end

    test "sends with wallet creation", %{socket: socket} do
      ref =
        push_doc(socket, @total_worth_changed_document,
          variables: %{"userId" => 1, "currency" => "USD"}
        )

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      ref =
        push_doc(socket, @create_wallet_document,
          variables: %{
            "userId" => 1,
            "value" => 500_000,
            "currency" => "CAD"
          }
        )

      assert_reply ref, :ok, reply

      assert %{data: %{"createWallet" => %{"currency" => "CAD", "value" => 500_000}}} = reply

      expected = %{
        result: %{data: %{"totalWorthChanged" => %{"currency" => "USD", "value" => 90_000_000}}},
        subscriptionId: subscription_id
      }

      assert_push "subscription:data", push
      assert expected == push
    end
  end
end
