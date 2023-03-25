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

  subscription do
    field :total_worth_changed, :money do
      arg :user_id, non_null(:integer)
      arg :currency, non_null(:string)

      trigger [:send_money, :create_wallet],
        topic: fn
          %{sender: sender} ->
            "total_worth_change/#{sender.id}"

          %{user_id: user_id} ->
            "total_worth_change/#{user_id}"

          _ ->
            "total_worth_change"
        end

      config fn args, _ ->
        {:ok, topic: "total_worth_change/#{args.user_id}"}
      end

      resolve &PaymentServerWeb.Resolvers.User.get_total_worth/3
    end
  end
end
