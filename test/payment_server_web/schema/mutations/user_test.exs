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
end
