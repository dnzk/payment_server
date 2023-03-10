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

      assert json_response(response, 200) == %{
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

      assert json_response(response, 200) == %{
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

      assert json_response(response, 200) == %{
               "data" => %{
                 "user" => nil
               }
             }
    end
  end
end
