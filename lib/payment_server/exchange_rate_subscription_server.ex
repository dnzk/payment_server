defmodule PaymentServer.ExchangeRateSubscriptionServer do
  @moduledoc """
  Exchange rate subscription server
  """

  alias PaymentServer.ExchangeRateSubscriptionServer
  alias PaymentServer.Tasks.ExchangeRate
  alias __MODULE__
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: ExchangeRateSubscriptionServer)
  end

  def request_exchange_rate(%{from: _from, to: _to} = args) do
    GenServer.cast(__MODULE__, {:request_exchange_rate, args})
  end

  def request_all_exchange_rate do
    GenServer.cast(__MODULE__, {:request_all_exchange_rate})
  end

  def get_latest_exchange_rate(key) do
    GenServer.call(__MODULE__, {:get_latest_exchange_rate, key})
  end

  def update_exchange_rate(key, rate) do
    GenServer.cast(__MODULE__, {:update_exchange_rate, %{key: key, rate: rate}})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:request_exchange_rate, %{from: _from, to: _to} = args}, state) do
    maybe_run_interval_request(state, args)
    {:noreply, Map.update(state, keyify(args), nil, & &1)}
  end

  @impl true
  def handle_cast({:request_all_exchange_rate}, state) do
    pairs = PaymentServer.get_currency_pairs()
    for p <- pairs, do: maybe_run_interval_request(state, p)

    state =
      pairs
      |> Enum.reduce(%{}, fn p, acc ->
        Map.update(acc, keyify(p), nil, & &1)
      end)
      |> Map.merge(state)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_exchange_rate, %{key: key, rate: rate}}, state) do
    {:noreply, Map.update(state, key, nil, fn _ -> rate end)}
  end

  @impl true
  def handle_call({:get_latest_exchange_rate, key}, _from, state) do
    {:reply, Map.fetch(state, key), state}
  end

  defp maybe_run_interval_request(state, %{from: _from, to: _to} = args) do
    if !Map.has_key?(state, keyify(args)) do
      run_interval_request(args)
    end
  end

  defp run_interval_request(args) do
    spawn(fn ->
      :timer.apply_interval(1000, ExchangeRateSubscriptionServer, :request_and_emit, [args])

      :timer.sleep(:infinity)
    end)
  end

  def request_and_emit(args) do
    args
    |> ExchangeRate.request_exchange_rate()
    |> ExchangeRate.get_exchange_rate_response()
    |> ExchangeRate.get_exchange_rate()
    |> maybe_publish_absinthe_event(args)
  end

  defp maybe_publish_absinthe_event(exchange_rate, %{from: _from, to: _to} = args) do
    value =
      args
      |> keyify
      |> ExchangeRateSubscriptionServer.get_latest_exchange_rate()

    case value do
      {:ok, last_value} ->
        if last_value === exchange_rate do
          nil
        else
          publish_absinthe_event(exchange_rate, args, keyify(args))
        end

      _ ->
        nil
    end
  end

  defp publish_absinthe_event(exchange_rate, %{from: from, to: to} = args, topic) do
    spawn_update_exchange_rate(args, exchange_rate)

    Absinthe.Subscription.publish(
      PaymentServerWeb.Endpoint,
      %{from_currency: from, to_currency: to, exchange_rate: exchange_rate},
      all_exchange_rate_updated: "*/*"
    )

    Absinthe.Subscription.publish(
      PaymentServerWeb.Endpoint,
      %{from_currency: from, to_currency: to, exchange_rate: exchange_rate},
      exchange_rate_updated: topic
    )
  end

  defp spawn_update_exchange_rate(%{from: _from, to: _to} = args, exchange_rate) do
    spawn(fn ->
      args
      |> keyify()
      |> ExchangeRateSubscriptionServer.update_exchange_rate(exchange_rate)
    end)
  end

  defp keyify(%{from: from, to: to}) do
    "#{from}/#{to}"
  end
end
