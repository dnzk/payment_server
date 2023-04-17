defmodule PaymentServerWeb.Resolvers.Wallet do
  @moduledoc """
  Wallet resolvers
  """
  def list_wallets(_root, %{user_id: _user_id} = args, _info) do
    {:ok, PaymentServer.list_wallets(args)}
  end

  def get_wallet(_root, args, _info) do
    {:ok, PaymentServer.get_wallet(args)}
  end

  def create_wallet(_root, %{user_id: _user_id, value: _value, currency: _currency} = args, _info) do
    PaymentServer.create_wallet(args)
  end

  def send_money(
        _root,
        %{sender_account_number: _, recipient_account_number: _, value: _} = args,
        _info
      ) do
    PaymentServer.send_money(args)
  end
end
