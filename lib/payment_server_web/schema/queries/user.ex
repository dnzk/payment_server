defmodule PaymentServerWeb.Schema.Queries.User do
  @moduledoc """
  User queries
  """

  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers

  object :user_queries do
    @desc "Get all users"
    field :users, list_of(:user) do
      resolve &Resolvers.User.list_users/3
    end

    @desc "Get a user"
    field :user, :user do
      arg :id, non_null(:integer)
      resolve &Resolvers.User.get_user/3
    end

    field :wallets, list_of(:wallet) do
      arg :user_id, non_null(:integer)
      resolve &Resolvers.User.list_wallets/3
    end
  end
end
