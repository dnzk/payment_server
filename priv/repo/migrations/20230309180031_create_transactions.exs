defmodule PaymentServer.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table("transactions") do
      add :wallet_id, references(:wallets)
      add :type, :string
      add :counterparty, :integer
      add :balance, :bigint
      add :value, :bigint

      timestamps()
    end

    create index("transactions", [:wallet_id])
  end
end
