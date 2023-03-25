defmodule PaymentServer.User do
  @moduledoc """
  User schema
  """

  alias __MODULE__
  alias PaymentServer.Wallet
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %User{}

  schema "users" do
    field :name, :string
    field :email, :string

    timestamps()

    has_many :wallets, Wallet
  end

  def changeset(%User{} = user, params \\ %{}) do
    user
    |> cast(params, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_length(:name, min: 2)
    |> validate_length(:email, min: 3)
    |> validate_format(:email, ~r/@/)
  end
end
