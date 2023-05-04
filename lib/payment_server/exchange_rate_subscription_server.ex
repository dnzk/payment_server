defmodule PaymentServer.ExchangeRateSubscriptionServer do
  @moduledoc """
  Exchange rate subscription server
  """

  alias PaymentServer.ExchangeRateSubscriptionServer
  alias PaymentServer.Tasks.ExchangeRate
  alias __MODULE__
  use GenServer
  require Logger

  # Client API
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

  def reset do
    if Application.get_env(:payment_server, :test, false) do
      GenServer.cast(__MODULE__, {:reset_state})
    else
      raise "Incorrect function access"
    end
  end

  # Server handlers
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
    pairs = PaymentServer.Accounts.get_currency_pairs()
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
  def handle_cast({:reset_state}, _state) do
    {:noreply, %{}}
  end

  @impl true
  def handle_call({:get_latest_exchange_rate, key}, _from, state) do
    {:reply, Map.fetch(state, key), state}
  end

  defp maybe_run_interval_request(state, %{from: _from, to: _to} = args) do
    unless Map.has_key?(state, keyify(args)) do
      run_interval_request(args)
    end
  end

  @interval_ms 1000

  defp run_interval_request(args) do
    Task.Supervisor.start_child(
      PaymentServer.TaskSupervisor,
      fn ->
        request_and_emit(args)
        Process.sleep(@interval_ms)
        run_interval_request(args)
      end
    )
  end

  def request_and_emit(args) do
    with req <- ExchangeRate.request_exchange_rate(args),
         response <- ExchangeRate.get_exchange_rate_response(req),
         {:ok, rate} <- ExchangeRate.get_exchange_rate(response) do
      maybe_publish_absinthe_event(rate, args)
    else
      err ->
        Logger.error(inspect(err))
    end
  end

  defp maybe_publish_absinthe_event(exchange_rate, %{from: _from, to: _to} = args) do
    value =
      args
      |> keyify
      |> get_latest_exchange_rate()

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
      all_exchange_rate_updated: "*/*",
      exchange_rate_updated: topic
    )
  end

  defp spawn_update_exchange_rate(%{from: _from, to: _to} = args, exchange_rate) do
    Task.async(fn ->
      args
      |> keyify()
      |> update_exchange_rate(exchange_rate)
    end)
  end

  defp keyify(%{from: from, to: to}) do
    "#{from}/#{to}"
  end
end
