defmodule PaymentServerWeb.Schema.Objects.User do
  @moduledoc """
  User objects
  """

  use Absinthe.Schema.Notation

  @desc "A user"
  object :user do
    @desc "User id"
    field :id, :integer
    @desc "User name"
    field :name, :string
    @desc "User email"
    field :email, :string
  end
end
