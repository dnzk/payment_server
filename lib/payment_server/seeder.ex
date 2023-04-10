defmodule PaymentServer.Seeder do
  @moduledoc """
  Database seeder
  """
  alias PaymentServer.{Repo, User}

  def run do
    user_1 =
      Repo.insert!(%User{
        name: "User 1",
        email: "user_1@example.com"
      })

    user_2 =
      Repo.insert!(%User{
        name: "User 2",
        email: "user_2@example.com"
      })

    _user_3 =
      Repo.insert!(%User{
        name: "User 3",
        email: "user_3@example.com"
      })

    user_1_wallet_1 =
      user_1
      |> Ecto.build_assoc(:wallets, value: 1_000_000, currency: "USD", account_number: 123_456)
      |> Repo.insert!()

    user_1_wallet_2 =
      user_1
      |> Ecto.build_assoc(:wallets, value: 500_000, currency: "EUR", account_number: 123_457)
      |> Repo.insert!()

    user_2_wallet_1 =
      user_2
      |> Ecto.build_assoc(:wallets, value: 850_000, currency: "EUR", account_number: 333_222)
      |> Repo.insert!()

    user_1_wallet_1
    |> Ecto.build_assoc(:transactions,
      type: :created,
      counterparty: user_1_wallet_1.id,
      balance: user_1_wallet_1.value
    )
    |> Repo.insert!()

    user_1_wallet_2
    |> Ecto.build_assoc(:transactions,
      type: :created,
      counterparty: user_1_wallet_2.id,
      balance: user_1_wallet_2.value
    )
    |> Repo.insert!()

    user_2_wallet_1
    |> Ecto.build_assoc(:transactions,
      type: :created,
      counterparty: user_2_wallet_1.id,
      balance: user_2_wallet_1.value
    )
    |> Repo.insert!()
  end
end
