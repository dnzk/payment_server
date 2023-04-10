defmodule PaymentServerWeb.Schema.Queries.UserTest do
  @moduledoc """
  User queries test
  """

  use PaymentServerWeb.ConnCase, async: true

  describe "@users" do
    @list_users_document """
    query ListUsers {
      users {
        id
        name
        email
      }
    }
    """

    test "returns list of all users" do
      conn = build_conn()
      response = get conn, "/api", query: @list_users_document

      assert json_response(response, 200) === %{
               "data" => %{
                 "users" => [
                   %{
                     "email" => "user_1@example.com",
                     "id" => 1,
                     "name" => "User 1"
                   },
                   %{
                     "email" => "user_2@example.com",
                     "id" => 2,
                     "name" => "User 2"
                   },
                   %{
                     "email" => "user_3@example.com",
                     "id" => 3,
                     "name" => "User 3"
                   }
                 ]
               }
             }
    end
  end

  describe "@user" do
    @get_user_document """
    query GetUser($id: Int!) {
      user(id: $id) {
        id
        name
        email
      }
    }
    """

    test "returns a single user" do
      conn = build_conn()

      response =
        post conn, "/api",
          query: @get_user_document,
          variables: %{
            "id" => 1
          }

      assert json_response(response, 200) === %{
               "data" => %{
                 "user" => %{
                   "id" => 1,
                   "email" => "user_1@example.com",
                   "name" => "User 1"
                 }
               }
             }
    end

    test "returns nil when user doesn't exist" do
      conn = build_conn()

      response =
        post conn, "/api",
          query: @get_user_document,
          variables: %{
            "id" => 5
          }

      assert json_response(response, 200) === %{
               "data" => %{
                 "user" => nil
               }
             }
    end
  end

  describe "@wallets" do
    @list_wallets_document """
    query ListWallets($userId: Int!) {
      wallets(userId: $userId) {
        id
        accountNumber
        currency
        value
      }
    }
    """

    test "returns all wallets that belong to a user" do
      conn = build_conn()

      response =
        post conn, "/api",
          query: @list_wallets_document,
          variables: %{
            "userId" => 1
          }

      assert json_response(response, 200) === %{
               "data" => %{
                 "wallets" => [
                   %{
                     "accountNumber" => 123_456,
                     "currency" => "USD",
                     "id" => 1,
                     "value" => 1_000_000
                   },
                   %{
                     "accountNumber" => 123_457,
                     "currency" => "EUR",
                     "id" => 2,
                     "value" => 500_000
                   }
                 ]
               }
             }
    end
  end

  describe "@wallet" do
    @get_wallet_document """
    query GetWallet($userId: Int!, $currency: String!) {
      wallet(userId: $userId, currency: $currency) {
        id
        accountNumber
        value
        currency
      }
    }
    """
    test "returns a wallet by user_id and currency" do
      conn = build_conn()

      response =
        post conn, "/api",
          query: @get_wallet_document,
          variables: %{
            "userId" => 1,
            "currency" => "USD"
          }

      assert json_response(response, 200) ==
               %{
                 "data" => %{
                   "wallet" => %{
                     "id" => 1,
                     "accountNumber" => 123_456,
                     "currency" => "USD",
                     "value" => 1_000_000
                   }
                 }
               }
    end

    @get_wallet_document """
    query GetWallet($accountNumber: Int!) {
      wallet(accountNumber: $accountNumber) {
        id
        value
        accountNumber
        currency
      }
    }
    """

    test "returns wallet by account number" do
      conn = build_conn()

      response =
        post conn, "/api",
          query: @get_wallet_document,
          variables: %{
            "accountNumber" => 123_457
          }

      assert json_response(response, 200) === %{
               "data" => %{
                 "wallet" => %{
                   "accountNumber" => 123_457,
                   "currency" => "EUR",
                   "id" => 2,
                   "value" => 500_000
                 }
               }
             }
    end
  end

  describe "@totalWorth" do
    @get_total_worth_document """
    query GetTotalWorth($userId: Int!, $currency: String!) {
      total_worth(userId: $userId, currency: $currency) {
        value
        currency
      }
    }
    """

    test "returns user total worth in the supplied currency" do
      conn = build_conn()

      response =
        post conn, "/api",
          query: @get_total_worth_document,
          variables: %{
            "userId" => 1,
            "currency" => "USD"
          }

      assert json_response(response, 200) === %{
               "data" => %{
                 "total_worth" => %{
                   "currency" => "USD",
                   "value" => 45_500_000
                 }
               }
             }
    end
  end
end
