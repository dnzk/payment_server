defmodule PaymentServer.Accounts.Transaction do
  @moduledoc """
  Transaction schema
  """

  alias __MODULE__
  alias PaymentServer.Accounts.Wallet
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %Transaction{}

  schema "transactions" do
    field :type, Ecto.Enum, values: [:created, :inbound, :outbound]
    field :counterparty, :integer
    field :balance, :integer
    field :value, :integer

    timestamps()

    belongs_to :wallet, Wallet
  end

  def changeset(%Transaction{} = transaction, params \\ %{}) do
    transaction
    |> cast(params, [:counterparty, :balance, :value, :type])
    |> validate_required([:type, :counterparty, :balance, :value, :type])
  end
end
