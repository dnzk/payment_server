defmodule PaymentServerWeb.Schema.Queries.Wallet do
  @moduledoc """
  Wallet queries
  """

  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers

  object :wallet_queries do
    @desc "List wallets by user id"
    field :wallets, list_of(:wallet) do
      arg :user_id, non_null(:integer)
      resolve &Resolvers.Wallet.list_wallets/3
    end

    @desc "Get a specific wallet"
    field :wallet, :wallet do
      arg :user_id, :integer
      arg :currency, :string
      arg :account_number, :integer
      resolve &Resolvers.Wallet.get_wallet/3
    end
  end
end
