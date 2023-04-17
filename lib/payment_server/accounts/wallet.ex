defmodule PaymentServer.Accounts.Wallet do
  @moduledoc """
  Wallet schema
  """

  alias __MODULE__
  alias PaymentServer.Repo
  alias PaymentServer.Accounts.{User, Transaction}
  use Ecto.Schema

  import Ecto.{Changeset, Query}

  @type t :: %Wallet{}

  schema "wallets" do
    field :value, :integer
    field :currency, :string
    field :account_number, :integer

    timestamps()

    belongs_to :user, User, foreign_key: :user_id, references: :id
    has_many :transactions, Transaction
  end

  def create_changeset(%Wallet{} = wallet, params \\ %{}) do
    wallet
    |> cast(params, [:value, :currency, :user_id])
    |> validate_required([:value, :currency, :user_id])
    |> validate_length(:currency, is: 3)
    |> update_change(:currency, &String.upcase/1)
    |> put_change(:account_number, generate_account_number())
    |> unique_constraint([:currency, :user_id],
      name: :wallets_user_id_currency_index,
      message: "has been created before"
    )
  end

  def changeset(%Wallet{} = wallet, params \\ %{}) do
    wallet
    |> cast(params, [:value, :currency, :account_number])
    |> validate_required([:value, :currency, :account_number])
  end

  def update_value(:recipient, %Wallet{} = wallet, value) do
    changeset(wallet, %{value: wallet.value + value})
  end

  def update_value(:sender, %Wallet{} = wallet, value) do
    changeset(wallet, %{value: wallet.value - value})
  end

  def get_by_currency(query \\ Wallet, currency) do
    from q in query, where: q.currency == ^currency
  end

  def get_by_user_id(query \\ Wallet, user_id) do
    from q in query, where: q.user_id == ^user_id
  end

  def get_by_account_number(query \\ Wallet, account_number) do
    from q in query, where: q.account_number == ^account_number
  end

  defp generate_account_number do
    number =
      1..9
      |> Enum.map_join(fn _ ->
        :rand.uniform(9)
      end)
      |> String.to_integer()

    case Repo.one(lock_wallet_and_get_account_number(number)) do
      nil -> number
      _ -> generate_account_number()
    end
  end

  defp lock_wallet_and_get_account_number(account_number) do
    from w in Wallet,
      where: w.account_number == ^account_number,
      lock: "FOR UPDATE NOWAIT"
  end
end
