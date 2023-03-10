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
end
