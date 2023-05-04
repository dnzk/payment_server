defmodule PaymentServerWeb.Schema.Mutations.Wallet do
  @moduledoc """
  Wallet mutations
  """

  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers

  object :wallet_mutations do
    @desc "Creates a wallet"
    field :create_wallet, :wallet do
      arg :user_id, non_null(:integer)
      arg :value, non_null(:integer)
      arg :currency, non_null(:string)
      resolve &Resolvers.Wallet.create_wallet/3
    end

    @desc "Sends money from a wallet to another wallet"
    field :send_money, :updated_wallets do
      arg :sender_account_number, :integer
      arg :recipient_account_number, :integer
      arg :value, :integer
      resolve &Resolvers.Wallet.send_money/3
    end
  end
end
