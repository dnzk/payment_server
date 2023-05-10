defmodule PaymentServer.Accounts do
  @moduledoc """
  PaymentServer context
  """
  alias PaymentServer.Repo
  alias PaymentServer.Accounts.{User, Wallet, Transaction}
  alias PaymentServer.Tasks.ExchangeRate
  require Logger

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
  @spec list_users :: {:ok, [User.t()] | []}
  def list_users do
    {:ok, Repo.all(User)}
  end

  @doc """
  Gets a user by id

  ## Examples

      iex> user = PaymentServer.get_user(1)
      iex> user.id
      1

  """
  @spec get_user(String.t() | integer()) :: {:ok, User.t()} | {:ok, nil}
  def get_user(id) do
    {:ok, Repo.get(User, id)}
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
    with {:ok, user} when not is_nil(user) <- get_user(user_id),
         {:ok, wallet} <- create_wallet_for_user(user, value, currency) do
      {:ok, wallet}
    else
      {:error, error} ->
        {:error, error}

      _ ->
        {:error, "Error when creating wallet"}
    end
  end

  @doc """
  List all wallets of a user.

  ## Examles

      iex> [%Wallet{} | _] = PaymentServer.list_wallets(%{user_id: 1})

  """
  @spec list_wallets(%{required(:user_id) => String.t() | integer()}) :: {:ok, list(Wallet.t())}
  def list_wallets(%{user_id: user_id}) do
    {:ok,
     Wallet
     |> Wallet.get_by_user_id(user_id)
     |> Repo.all()}
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
        }) :: {:ok, Wallet.t()} | {:ok, nil}
  def get_wallet(%{user_id: user_id, currency: currency}) do
    wallet =
      Wallet
      |> Wallet.get_by_user_id(user_id)
      |> Wallet.get_by_currency(String.upcase(currency))
      |> Repo.one()

    {:ok, wallet}
  end

  @spec get_wallet(%{required(:account_number) => integer()}) :: {:ok, Wallet.t()} | {:ok, nil}
  def get_wallet(%{account_number: account_number}) do
    wallet =
      Wallet
      |> Wallet.get_by_account_number(account_number)
      |> Repo.one()

    {:ok, wallet}
  end

  @spec get_total_worth(%{:currency => String.t(), :user_id => integer(), optional(any) => any}) ::
          {:ok, %{currency: String.t(), value: float()}}
  def get_total_worth(%{user_id: user_id, currency: currency}) do
    total =
      %{user_id: user_id}
      |> list_wallets()
      |> Kernel.elem(1)
      |> Enum.reduce(0, fn wallet, acc ->
        wallet.currency
        |> request_currency_exchange?(currency)
        |> maybe_convert_currency(wallet.currency, currency, wallet.value)
        |> Kernel.+(acc)
      end)

    {:ok, %{currency: currency, value: total}}
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
      when sender_account_number === recipient_account_number,
      do: {:error, "Cannot send money to the same wallet"}

  def send_money(%{sender_account_number: _, recipient_account_number: _, value: value})
      when not is_integer(value),
      do: {:error, "Value must be integer"}

  def send_money(
        %{
          sender_account_number: _sender_account_number,
          recipient_account_number: _recipient_account_number,
          value: sent_value
        } = args
      ) do
    case prepare_wallets_for_sending(args) do
      {:ok, wallets} ->
        %{
          sender_wallet: %{currency: sender_currency} = sender_wallet,
          recipient_wallet: %{currency: recipient_currency} = recipient_wallet
        } = wallets

        sender_currency
        |> request_currency_exchange?(recipient_currency)
        |> attempt_send_money(sender_wallet, recipient_wallet, sent_value)

      _ ->
        {:error, "Error while sending money"}
    end
  end

  @spec get_currency_pairs :: list
  def get_currency_pairs do
    Wallet
    |> Repo.all()
    |> Stream.map(& &1.currency)
    |> Enum.uniq()
    |> transform_to_pairs()
  end

  ## Helper functions

  defp create_wallet_for_user(%User{} = user, value, currency) do
    user
    |> Ecto.build_assoc(:wallets)
    |> Wallet.create_changeset(%{value: value, currency: currency})
    |> Repo.insert()
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

  defp request_rate(from, to) do
    with req <- ExchangeRate.request_exchange_rate(%{from: from, to: to}),
         resp <- ExchangeRate.get_exchange_rate_response(req),
         {:ok, rate} <- ExchangeRate.get_exchange_rate(resp) do
      {:ok, rate}
    else
      err ->
        Logger.error(inspect(err))
        {:error, "Error while requesting rate"}
    end
  end

  defp format_sent_value(rate, value) do
    rate
    |> Kernel.*(100)
    |> Kernel.trunc()
    |> Kernel.*(value)
  end

  defp prepare_wallets_for_sending(%{
         sender_account_number: sender_account_number,
         recipient_account_number: recipient_account_number
       }) do
    with {:ok, sender_wallet} when not is_nil(sender_wallet) <-
           get_wallet(%{account_number: sender_account_number}),
         {:ok, recipient_wallet} when not is_nil(recipient_wallet) <-
           get_wallet(%{account_number: recipient_account_number}) do
      {:ok, %{sender_wallet: sender_wallet, recipient_wallet: recipient_wallet}}
    else
      _ -> {:error, "Wallet does not exist"}
    end
  end

  defp calculate_exchange(from_currency, to_currency, value) do
    case request_rate(from_currency, to_currency) do
      {:ok, rate} ->
        {:ok, format_sent_value(rate, value)}

      _ ->
        {:error, "Error requesting exchange rate"}
    end
  end

  defp attempt_send_money(
         false,
         sender_wallet,
         recipient_wallet,
         value
       ) do
    update_wallets_and_add_transactions(sender_wallet, recipient_wallet, value)
  end

  defp attempt_send_money(
         true,
         sender_wallet,
         recipient_wallet,
         sent_value
       ) do
    case calculate_exchange(sender_wallet.currency, recipient_wallet.currency, sent_value) do
      {:ok, received_value} ->
        update_wallets_and_add_transactions(
          sender_wallet,
          recipient_wallet,
          sent_value,
          received_value
        )

      _ ->
        {:error, "Error while sending money"}
    end
  end

  defp update_wallets_and_add_transactions(%Wallet{} = sender, %Wallet{} = recipient, value) do
    Repo.transaction(fn ->
      with {:ok, updated_recipient} <- update_wallet_value(:recipient, recipient, value),
           {:ok, updated_sender} <- update_wallet_value(:sender, sender, value),
           {:ok, _recipient_transaction} <-
             create_wallet_transaction(:inbound, updated_recipient, value, sender.id),
           {:ok, _sender_transaction} <-
             create_wallet_transaction(:outbound, updated_sender, value, recipient.id) do
        %{
          sender: updated_sender,
          recipient: updated_recipient
        }
      else
        _ ->
          Repo.rollback("Error while sending money")
      end
    end)
  end

  defp update_wallets_and_add_transactions(
         %Wallet{} = sender,
         %Wallet{} = recipient,
         sent_value,
         received_value
       ) do
    Repo.transaction(fn ->
      with {:ok, updated_recipient} <- update_wallet_value(:recipient, recipient, received_value),
           {:ok, updated_sender} <- update_wallet_value(:sender, sender, sent_value),
           {:ok, _recipient_transaction} <-
             create_wallet_transaction(:inbound, updated_recipient, received_value, sender.id),
           {:ok, _sender_transaction} <-
             create_wallet_transaction(:outbound, updated_sender, sent_value, recipient.id) do
        %{
          sender: updated_sender,
          recipient: updated_recipient
        }
      else
        _ ->
          Repo.rollback("Error while sending money")
      end
    end)
  end

  defp update_wallet_value(type, wallet, value) do
    type
    |> Wallet.update_value(wallet, value)
    |> Repo.update()
  end

  defp create_wallet_transaction(type, %Wallet{} = wallet, value, counterparty) do
    wallet
    |> Ecto.build_assoc(:transactions)
    |> Transaction.changeset(%{
      type: type,
      value: value,
      balance: wallet.value,
      counterparty: counterparty
    })
    |> Repo.insert()
  end

  defp maybe_convert_currency(true, from, to, value) do
    case calculate_exchange(from, to, value) do
      {:ok, converted_value} ->
        converted_value

      _ ->
        value
    end
  end

  defp maybe_convert_currency(false, _from, _to, value) do
    value
  end
end
