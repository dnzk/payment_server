defmodule PaymentServerWeb.Schema.Objects.Wallet do
  @moduledoc """
  Wallet objects
  """

  use Absinthe.Schema.Notation

  @desc "A wallet"
  object :wallet do
    @desc "Wallet id"
    field :id, :integer
    field :account_number, :integer
    field :value, :integer
    field :currency, :string
  end
end
