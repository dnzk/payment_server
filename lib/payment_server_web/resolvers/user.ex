defmodule PaymentServerWeb.Resolvers.User do
  @moduledoc """
  User resolvers
  """

  def list_users(_root, _args, _info) do
    {:ok, PaymentServer.list_users()}
  end

  def get_user(_root, %{id: id}, _info) do
    {:ok, PaymentServer.get_user(id)}
  end

  def list_wallets(_root, %{user_id: _user_id} = args, _info) do
    {:ok, PaymentServer.list_wallets(args)}
  end

  def get_wallet(_root, args, _info) do
    {:ok, PaymentServer.get_wallet(args)}
  end
end
