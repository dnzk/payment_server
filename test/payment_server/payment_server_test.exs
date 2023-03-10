defmodule PaymentServerTest do
  @moduledoc """
  PaymentServer tests
  """

  use PaymentServer.DataCase, async: true
  alias PaymentServer.Transaction
  alias PaymentServer.{Repo, User, Wallet}
  alias PaymentServer.Tasks.ExchangeRate
  import Ecto.Query
  doctest PaymentServer

  describe "create_user/1" do
    @user_name "User zero"
    @user_email "user_zero@example.com"
    test "creates user with valid params" do
      assert nil == Repo.get_by(User, name: @user_name)

      PaymentServer.create_user(%{
        name: @user_name,
        email: @user_email
      })

      assert Repo.get_by(User, name: @user_name) != nil
    end

    test "does not create user with invalid email" do
      assert {:error, _} = PaymentServer.create_user(%{name: @user_name, email: "invalid"})
    end

    test "does not create user when name is too short" do
      assert {:error, _} = PaymentServer.create_user(%{name: "a", email: @user_email})
    end
  end

  describe "list_users/0" do
    test "lists all users" do
      users = PaymentServer.list_users()

      assert length(users) == 3

      PaymentServer.create_user(%{
        name: "Extra user",
        email: "extra_user@example.com"
      })

      users = PaymentServer.list_users()

      assert length(users) == 4
    end
  end

  describe "get_user/1" do
    test "gets a single user" do
      assert %User{id: 1} = PaymentServer.get_user(1)
    end

    test "returns nil for unexisting user id" do
      assert nil == PaymentServer.get_user(100)
    end
  end

  describe "create_wallet/1" do
    test "creates a wallet" do
      user_1_wallets =
        from u in User,
          join: w in Wallet,
          on: w.user_id == u.id,
          where: u.id == 1

      assert length(Repo.all(user_1_wallets)) == 2

      PaymentServer.create_wallet(%{user_id: 1, value: 5_000_00, currency: "IDR"})

      assert length(Repo.all(user_1_wallets)) == 3
    end

    test "prevents creation of invalid currency format" do
      assert {:error, %Ecto.Changeset{}} =
               PaymentServer.create_wallet(%{user_id: 1, value: 400_00, currency: "UIOP"})
    end

    test "makes sure currency is uppercased" do
      assert {:ok, %Wallet{} = wallet} =
               PaymentServer.create_wallet(%{user_id: 1, value: 5000_00, currency: "jpy"})

      assert wallet.currency == "JPY"
    end

    test "prevents creation of duplicate currency per user" do
      assert {:ok, _} =
               PaymentServer.create_wallet(%{user_id: 2, value: 5_000_00, currency: "USD"})

      assert {:error, _} =
               PaymentServer.create_wallet(%{user_id: 2, value: 10_000_00, currency: "USD"})
    end

    test "adds account number to wallet" do
      assert {:ok, %Wallet{} = wallet} =
               PaymentServer.create_wallet(%{user_id: 3, value: 5_000_00, currency: "USD"})

      assert wallet.account_number != nil
      assert is_integer(wallet.account_number) == true
    end

    test "prevents creation of wallet for nonexistent user" do
      assert {:error, _} =
               PaymentServer.create_wallet(%{user_id: 11, value: 5_000_00, currency: "JPY"})
    end
  end

  describe "get_wallet/1" do
    test "gets wallet by user_id and currency" do
      assert wallet = PaymentServer.get_wallet(%{user_id: 1, currency: "USD"})
      assert wallet.currency == "USD"
    end

    test "gets wallet by account_number" do
      wallet = Repo.get(Wallet, 1)
      fetched_wallet = PaymentServer.get_wallet(%{account_number: wallet.account_number})
      assert fetched_wallet.id == wallet.id
    end

    test "returns nil for nonexisting wallet" do
      assert nil == PaymentServer.get_wallet(%{user_id: 1, currency: "IDR"})
    end
  end

  describe "send_money/1" do
    test "returns error when sender and recipient is the same" do
      wallet = Repo.get(Wallet, 1)

      assert {:error, _} =
               PaymentServer.send_money(%{
                 sender_account_number: wallet.account_number,
                 recipient_account_number: wallet.account_number,
                 value: 5_000_00
               })
    end

    test "returns error when value is not integer" do
      wallet_1 = Repo.get(Wallet, 1)
      wallet_2 = Repo.get(Wallet, 2)

      assert {:error, _} =
               PaymentServer.send_money(%{
                 sender_account_number: wallet_1.account_number,
                 recipient_account_number: wallet_2.account_number,
                 value: 500.50
               })

      assert {:error, _} =
               PaymentServer.send_money(%{
                 sender_account_number: wallet_1.account_number,
                 recipient_account_number: wallet_2.account_number,
                 value: "500_50"
               })
    end

    test "sends money when sender and recipient have the same currency" do
      wallet_1 = PaymentServer.get_wallet(%{user_id: 1, currency: "EUR"})
      wallet_2 = PaymentServer.get_wallet(%{user_id: 2, currency: "EUR"})

      wallet_1_transactions_count = transactions_count(wallet_1.id)

      wallet_2_transactions_count = transactions_count(wallet_2.id)

      value = 5_000_00

      assert {:ok, %{sender: sender, recipient: recipient}} =
               PaymentServer.send_money(%{
                 sender_account_number: wallet_1.account_number,
                 recipient_account_number: wallet_2.account_number,
                 value: value
               })

      assert sender.value == wallet_1.value - value
      assert recipient.value == wallet_2.value + value

      assert transactions_count(wallet_1.id) == wallet_1_transactions_count + 1
      assert transactions_count(wallet_2.id) == wallet_2_transactions_count + 1
    end

    test "converts currency from sender to recipient before sending when sender and recipient have different currency" do
      wallet_1 = PaymentServer.get_wallet(%{user_id: 1, currency: "USD"})
      wallet_2 = PaymentServer.get_wallet(%{user_id: 2, currency: "EUR"})
      value = 500_00

      PaymentServer.send_money(%{
        sender_account_number: wallet_1.account_number,
        recipient_account_number: wallet_2.account_number,
        value: value
      })

      # NOTE:
      # The constant exchange rate is only made possible by
      # the unchanging response from the mock server
      exchange_rate =
        ExchangeRate.request_exchange_rate(%{from: "USD", to: "EUR"})
        |> ExchangeRate.get_exchange_rate_response()
        |> ExchangeRate.get_exchange_rate()

      updated_wallet_1 = PaymentServer.get_wallet(%{user_id: 1, currency: "USD"})
      updated_wallet_2 = PaymentServer.get_wallet(%{user_id: 2, currency: "EUR"})

      assert updated_wallet_1.value == wallet_1.value - value
      assert updated_wallet_2.value == wallet_2.value + value * exchange_rate
    end

    defp transactions_count(wallet_id) do
      Repo.one(from t in Transaction, where: t.wallet_id == ^wallet_id, select: count())
    end
  end

  describe "list_wallets/1" do
    test "returns all wallets that belong to a user" do
      [%Wallet{user_id: user_id} | _] = PaymentServer.list_wallets(%{user_id: 1})

      assert user_id == 1
    end
  end

  describe "get_total_worth/1" do
    test "gets user's total worth by the given currency" do
      assert %{currency: "USD", value: 45_500_000} ==
               PaymentServer.get_total_worth(%{user_id: 1, currency: "USD"})
    end
  end
end
