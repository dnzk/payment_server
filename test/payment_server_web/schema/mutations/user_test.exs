defmodule PaymentServerWeb.Schema.Mutations.UserTest do
  @moduledoc """
  User mutations test
  """
  use PaymentServerWeb.ConnCase, async: true
  alias PaymentServer.{Repo, Accounts}
  alias Accounts.User

  describe "@create_user" do
    @create_user_document """
    mutation CreateUser($name: String!, $email: String!) {
      createUser(name: $name, email: $email) {
        id
        name
        email
      }
    }
    """

    test "creates a user with valid params" do
      user_name = "New User"
      conn = build_conn()

      assert is_nil(Repo.get_by(User, name: user_name))

      post conn, "/api",
        query: @create_user_document,
        variables: %{
          "name" => user_name,
          "email" => "new_user@example.com"
        }

      assert %{name: name} = Repo.get_by(User, name: user_name)
      assert name === user_name
    end
  end

  describe "@create_wallet" do
    @create_wallet_document """
    mutation CreateWallet($userId: Int!, $value: Int!, $currency: String!) {
      createWallet(userId: $userId, value: $value, currency: $currency) {
        id
        value
        currency
      }
    }
    """

    test "creates wallet with valid params" do
      assert is_nil(Accounts.get_wallet(%{user_id: 2, currency: "JPY"}))
      conn = build_conn()

      post conn, "/api",
        query: @create_wallet_document,
        variables: %{
          "userId" => 2,
          "currency" => "JPY",
          "value" => 300_000
        }

      assert %{currency: _, value: _} = Accounts.get_wallet(%{user_id: 2, currency: "JPY"})
    end
  end

  describe "@send_money" do
    @send_money_document """
    mutation SendMoney($senderAccountNumber: Int!, $recipientAccountNumber: Int!, $value: Int!) {
      sendMoney(senderAccountNumber: $senderAccountNumber, recipientAccountNumber: $recipientAccountNumber, value: $value) {
        sender {
          value
          currency
        }
        recipient {
          value
          currency
        }
      }
    }
    """

    test "sends money with valid params" do
      conn = build_conn()
      wallet_1 = Accounts.get_wallet(%{user_id: 1, currency: "USD"})
      wallet_2 = Accounts.get_wallet(%{user_id: 2, currency: "EUR"})

      response =
        post conn, "/api",
          query: @send_money_document,
          variables: %{
            "senderAccountNumber" => wallet_1.account_number,
            "recipientAccountNumber" => wallet_2.account_number,
            "value" => 50_000
          }

      assert json_response(response, 200) ===
               %{
                 "data" => %{
                   "sendMoney" => %{
                     "recipient" => %{"currency" => "EUR", "value" => 5_300_000},
                     "sender" => %{"currency" => "USD", "value" => 950_000}
                   }
                 }
               }
    end
  end
end
