defmodule PaymentServerWeb.Resolvers.User do
  @moduledoc """
  User resolvers
  """

  alias PaymentServer.Accounts

  @spec list_users(any(), any(), any()) :: {:ok, [PaymentServer.Accounts.User.t()]}
  def list_users(_root, _args, _info) do
    Accounts.list_users()
  end

  @spec get_user(any, %{:id => binary | integer, optional(any) => any}, any) ::
          {:ok, nil | PaymentServer.Accounts.User.t()}
  def get_user(_root, %{id: id}, _info) do
    Accounts.get_user(id)
  end

  @spec get_total_worth(
          any,
          %{:currency => binary, :user_id => integer, optional(any) => any},
          any
        ) :: {:ok, %{currency: binary, value: float}}
  def get_total_worth(_root, %{user_id: _user_id, currency: _currency} = args, _info) do
    Accounts.get_total_worth(args)
  end

  @spec create_user(any, %{email: binary, name: binary}, any) ::
          {:error, Ecto.Changeset.t()} | {:ok, PaymentServer.Accounts.User.t()}
  def create_user(_root, %{name: _name, email: _email} = args, _info) do
    Accounts.create_user(args)
  end
end
