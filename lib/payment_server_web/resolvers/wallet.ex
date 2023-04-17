defmodule PaymentServerWeb.Resolvers.Wallet do
  @moduledoc """
  Wallet resolvers
  """

  alias PaymentServer.Accounts

  def list_wallets(_root, %{user_id: _user_id} = args, _info) do
    {:ok, Accounts.list_wallets(args)}
  end

  def get_wallet(_root, args, _info) do
    {:ok, Accounts.get_wallet(args)}
  end

  def create_wallet(_root, %{user_id: _user_id, value: _value, currency: _currency} = args, _info) do
    Accounts.create_wallet(args)
  end

  def send_money(
        _root,
        %{sender_account_number: _, recipient_account_number: _, value: _} = args,
        _info
      ) do
    Accounts.send_money(args)
  end
end
