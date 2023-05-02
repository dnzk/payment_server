defmodule PaymentServerWeb.Resolvers.Wallet do
  @moduledoc """
  Wallet resolvers
  """

  alias PaymentServer.Accounts

  @spec list_wallets(any, %{user_id: binary | integer}, any) ::
          {:ok, [PaymentServer.Accounts.Wallet.t()]}
  def list_wallets(_root, %{user_id: _user_id} = args, _info) do
    Accounts.list_wallets(args)
  end

  @spec get_wallet(
          any,
          %{
            optional(:account_number) => integer,
            optional(:currency) => binary,
            optional(:user_id) => binary | integer
          },
          any
        ) :: {:ok, nil | PaymentServer.Accounts.Wallet.t()}
  def get_wallet(_root, args, _info) do
    Accounts.get_wallet(args)
  end

  @spec create_wallet(any, %{currency: integer, user_id: binary | integer, value: integer}, any) ::
          {:error, binary | Ecto.Changeset.t()} | {:ok, PaymentServer.Accounts.Wallet.t()}
  def create_wallet(_root, %{user_id: _user_id, value: _value, currency: _currency} = args, _info) do
    Accounts.create_wallet(args)
  end

  @spec send_money(
          any,
          %{recipient_account_number: integer, sender_account_number: integer, value: integer},
          any
        ) ::
          {:error, binary}
          | {:ok,
             %{
               recipient: PaymentServer.Accounts.Wallet.t(),
               sender: PaymentServer.Accounts.Wallet.t()
             }}
  def send_money(
        _root,
        %{sender_account_number: _, recipient_account_number: _, value: _} = args,
        _info
      ) do
    Accounts.send_money(args)
  end
end
