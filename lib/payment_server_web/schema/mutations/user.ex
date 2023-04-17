defmodule PaymentServerWeb.Schema.Mutations.User do
  @moduledoc """
  User mutations
  """

  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers

  object :user_mutations do
    @desc "Creates a user"
    field :create_user, :user do
      arg :name, non_null(:string)
      arg :email, non_null(:string)
      resolve &Resolvers.User.create_user/3
    end
  end
end
