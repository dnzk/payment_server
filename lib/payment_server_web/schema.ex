defmodule PaymentServerWeb.Schema do
  @moduledoc """
  Schema
  """
  alias PaymentServer.ExchangeRateSubscriptionServer

  use Absinthe.Schema

  # objects
  import_types PaymentServerWeb.Schema.Objects.User
  import_types PaymentServerWeb.Schema.Objects.Wallet

  # queries
  import_types PaymentServerWeb.Schema.Queries.User
  import_types PaymentServerWeb.Schema.Queries.Wallet

  # mutations
  import_types PaymentServerWeb.Schema.Mutations.User
  import_types PaymentServerWeb.Schema.Mutations.Wallet

  query do
    import_fields :user_queries
    import_fields :wallet_queries
  end

  mutation do
    import_fields :user_mutations
    import_fields :wallet_mutations
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

    field :exchange_rate_updated, :currency_exchange do
      arg :from_currency, non_null(:string)
      arg :to_currency, non_null(:string)

      config fn %{from_currency: from, to_currency: to}, _ ->
        ExchangeRateSubscriptionServer.request_exchange_rate(%{
          from: from,
          to: to
        })

        {:ok, topic: "#{from}/#{to}"}
      end
    end

    field :all_exchange_rate_updated, :currency_exchange do
      config fn _, _ ->
        ExchangeRateSubscriptionServer.request_all_exchange_rate()
        {:ok, topic: "*/*"}
      end
    end
  end
end
