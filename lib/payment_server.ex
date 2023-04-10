defmodule PaymentServer do
  @moduledoc """
  PaymentServer context
  """
  alias PaymentServer.{Repo, User, Wallet, Transaction}
  alias PaymentServer.Tasks.ExchangeRate

  @doc """
  Creates a user

  ## Examples

      iex> {:ok, user} = PaymentServer.create_user(%{name: "user", email: "user@example.com"})
      iex> user.name
      "user"
      iex> user.email
      "user@example.com"

  """
  @spec create_user(%{required(:name) => String.t(), required(:email) => String.t()}) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(%{name: _name, email: _email} = params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Lists all users

  ## Examples

      iex> [%User{} | _] = PaymentServer.list_users()

  """
  @spec list_users :: [User.t()] | []
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a user by id

  ## Examples

      iex> user = PaymentServer.get_user(1)
      iex> user.id
      1

  """
  @spec get_user(String.t() | integer()) :: User.t() | nil
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Creates a wallet


  ## Examples

      iex> {:ok, wallet} = PaymentServer.create_wallet(%{user_id: 1, value: 4_00_00, currency: "IDR"})
      iex> wallet.value
      40000
  """
  @spec create_wallet(%{
          required(:user_id) => String.t() | integer(),
          required(:value) => integer(),
          required(:currency) => integer()
        }) :: {:ok, Wallet.t()} | {:error, String.t()} | {:error, Ecto.Changeset.t()}
  def create_wallet(%{user_id: user_id, value: value, currency: currency}) do
    case get_user(user_id) do
      nil ->
        {:error, "User does not exist"}

      user ->
        user
        |> Ecto.build_assoc(:wallets)
        |> Wallet.create_changeset(%{value: value, currency: currency})
        |> Repo.insert()
    end
  end

  @doc """
  List all wallets of a user.

  ## Examles

      iex> [%Wallet{} | _] = PaymentServer.list_wallets(%{user_id: 1})

  """
  @spec list_wallets(%{required(:user_id) => String.t() | integer()}) :: list(Wallet.t())
  def list_wallets(%{user_id: user_id}) do
    Wallet
    |> Wallet.get_by_user_id(user_id)
    |> Repo.all()
  end

  @doc """
  Gets a wallet by combination of user_id and currency or account_number.

  ## Examples

      iex> wallet = PaymentServer.get_wallet(%{user_id: 1, currency: "USD"})
      iex> wallet.currency
      "USD"

  """
  @spec get_wallet(%{
          required(:user_id) => String.t() | integer(),
          required(:currency) => String.t()
        }) :: Wallet.t() | nil
  def get_wallet(%{user_id: user_id, currency: currency}) do
    Wallet
    |> Wallet.get_by_user_id(user_id)
    |> Wallet.get_by_currency(String.upcase(currency))
    |> Repo.one()
  end

  @spec get_wallet(%{required(:account_number) => integer()}) :: Wallet.t() | nil
  def get_wallet(%{account_number: account_number}) do
    Wallet
    |> Wallet.get_by_account_number(account_number)
    |> Repo.one()
  end

  def get_total_worth(%{user_id: user_id, currency: currency}) do
    total =
      %{user_id: user_id}
      |> list_wallets()
      |> Enum.reduce(0, fn wallet, acc ->
        acc + fetch_currency_exchange(wallet.currency, currency, wallet.value)
      end)

    %{currency: currency, value: total}
  end

  @doc """
  Sends money from one wallet to another.
  """
  @spec send_money(%{
          required(:sender_account_number) => integer(),
          required(:recipient_account_number) => integer(),
          value: integer()
        }) ::
          {:error, String.t()} | {:ok, %{sender: Wallet.t(), recipient: Wallet.t()}}
  def send_money(%{
        sender_account_number: sender_account_number,
        recipient_account_number: recipient_account_number,
        value: _value
      })
      when sender_account_number == recipient_account_number,
      do: {:error, "Cannot send money to the same wallet"}

  def send_money(%{sender_account_number: _, recipient_account_number: _, value: value})
      when not is_integer(value),
      do: {:error, "Value must be integer"}

  def send_money(%{
        sender_account_number: sender_account_number,
        recipient_account_number: recipient_account_number,
        value: value
      }) do
    with sender_wallet <- get_wallet(%{account_number: sender_account_number}),
         recipient_wallet <- get_wallet(%{account_number: recipient_account_number}) do
      case request_currency_exchange?(sender_wallet.currency, recipient_wallet.currency) do
        true ->
          moving_value =
            fetch_currency_exchange(
              sender_wallet.currency,
              recipient_wallet.currency,
              value
            )

          update_wallets_and_add_transactions(
            sender_wallet,
            recipient_wallet,
            value,
            moving_value
          )

        false ->
          update_wallets_and_add_transactions(
            sender_wallet,
            recipient_wallet,
            value
          )
      end
    end
  end

  def get_currency_pairs do
    Wallet
    |> Repo.all()
    |> Stream.map(& &1.currency)
    |> Enum.uniq()
    |> transform_to_pairs()
  end

  defp transform_to_pairs(currencies) when is_list(currencies) do
    transform_to_pairs(currencies, currencies, [])
  end

  defp transform_to_pairs([hd | tl], currencies, result) do
    pairs =
      currencies
      |> Stream.filter(&(&1 !== hd))
      |> Enum.map(&%{from: hd, to: &1})

    transform_to_pairs(tl, currencies, [pairs | result])
  end

  defp transform_to_pairs([], _currencies, result), do: List.flatten(result)

  defp request_currency_exchange?(currency_a, currency_b)
       when is_binary(currency_a) and is_binary(currency_b) do
    String.upcase(currency_a) !== String.upcase(currency_b)
  end

  defp fetch_currency_exchange(from, to, value) when from == to do
    value
  end

  defp fetch_currency_exchange(from, to, value) do
    %{from: from, to: to}
    |> ExchangeRate.request_exchange_rate()
    |> ExchangeRate.get_exchange_rate_response()
    |> ExchangeRate.get_exchange_rate()
    |> clean_exchange_value()
    |> Kernel.*(value)
  end

  defp clean_exchange_value(value) when is_float(value) do
    value
    |> Kernel.*(100)
    |> Kernel.trunc()
  end

  defp update_wallets_and_add_transactions(%Wallet{} = sender, %Wallet{} = recipient, value) do
    Repo.transaction(fn ->
      updated_recipient = Repo.update!(Wallet.update_value(:recipient, recipient, value))

      updated_sender = Repo.update!(Wallet.update_value(:sender, sender, value))

      create_wallet_transaction!(:inbound, updated_recipient, value, sender.id)

      create_wallet_transaction!(:outbound, updated_sender, value, recipient.id)

      %{
        sender: updated_sender,
        recipient: updated_recipient
      }
    end)
  end

  defp update_wallets_and_add_transactions(
         %Wallet{} = sender,
         %Wallet{} = recipient,
         sent_value,
         received_value
       ) do
    Repo.transaction(fn ->
      updated_recipient = Repo.update!(Wallet.update_value(:recipient, recipient, received_value))

      updated_sender = Repo.update!(Wallet.update_value(:sender, sender, sent_value))

      create_wallet_transaction!(:inbound, updated_recipient, received_value, sender.id)

      create_wallet_transaction!(:outbound, updated_sender, sent_value, recipient.id)

      %{
        sender: updated_sender,
        recipient: updated_recipient
      }
    end)
  end

  defp create_wallet_transaction!(type, %Wallet{} = wallet, value, counterparty) do
    wallet
    |> Ecto.build_assoc(:transactions)
    |> Transaction.changeset(%{
      type: type,
      value: value,
      balance: wallet.value,
      counterparty: counterparty
    })
    |> Repo.insert!()
  end
end
