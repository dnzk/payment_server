defmodule PaymentServerWeb.Resolvers.User do
  @moduledoc """
  User resolvers
  """

  alias PaymentServer.Accounts

  def list_users(_root, _args, _info) do
    {:ok, Accounts.list_users()}
  end

  def get_user(_root, %{id: id}, _info) do
    {:ok, Accounts.get_user(id)}
  end

  def get_total_worth(_root, %{user_id: _user_id, currency: _currency} = args, _info) do
    {:ok, Accounts.get_total_worth(args)}
  end

  def create_user(_root, %{name: _name, email: _email} = args, _info) do
    Accounts.create_user(args)
  end
end
