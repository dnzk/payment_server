defmodule PaymentServer.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table("wallets") do
      add :value, :bigint
      add :currency, :string
      add :user_id, references(:users), null: false
      add :account_number, :integer
      add :balance, :bigint

      timestamps()
    end

    create index("wallets", [:user_id, :account_number])
    create unique_index("wallets", [:currency, :user_id], name: :wallets_user_id_currency_index)
  end
end
