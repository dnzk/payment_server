defmodule PaymentServerWeb.Schema.Mutations.UserTest do
  @moduledoc """
  User mutations test
  """
  use PaymentServerWeb.ConnCase, async: true
  alias PaymentServer.{Repo, User}

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

      assert nil == Repo.get_by(User, name: user_name)

      post conn, "/api",
        query: @create_user_document,
        variables: %{
          "name" => user_name,
          "email" => "new_user@example.com"
        }

      assert %{name: name} = Repo.get_by(User, name: user_name)
      assert name == user_name
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
      assert nil == PaymentServer.get_wallet(%{user_id: 2, currency: "JPY"})
      conn = build_conn()

      post conn, "/api",
        query: @create_wallet_document,
        variables: %{
          "userId" => 2,
          "currency" => "JPY",
          "value" => 300_000
        }

      assert %{currency: _, value: _} = PaymentServer.get_wallet(%{user_id: 2, currency: "JPY"})
    end
  end
end
