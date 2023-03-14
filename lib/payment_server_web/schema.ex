defmodule PaymentServerWeb.Schema do
  @moduledoc """
  Schema
  """

  use Absinthe.Schema

  # objects
  import_types PaymentServerWeb.Schema.Objects.User
  import_types PaymentServerWeb.Schema.Objects.Wallet

  # queries
  import_types PaymentServerWeb.Schema.Queries.User

  # mutations
  import_types PaymentServerWeb.Schema.Mutations.User

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :user_mutations
  end
end
