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

    @desc "Creates a wallet"
    field :create_wallet, :wallet do
      arg :user_id, non_null(:integer)
      arg :value, non_null(:integer)
      arg :currency, non_null(:string)
      resolve &Resolvers.User.create_wallet/3
    end

    # @desc "Sends money"
    field :send_money, :updated_wallets do
      arg :sender_account_number, :integer
      arg :recipient_account_number, :integer
      arg :value, :integer
      resolve &Resolvers.User.send_money/3
    end
  end
end
