defmodule PaymentServer.Tasks.ExchangeRate do
  @moduledoc """
  ExhangeRate Task module
  """
  def request_exchange_rate(%{from: _from, to: _to} = params) do
    Task.async(fn ->
      params
      |> exchange_rate_url()
      |> HTTPoison.get!()
    end)
  end

  def get_exchange_rate_response(%Task{} = request) do
    Task.await(request)
  end

  def get_exchange_rate(%HTTPoison.Response{status_code: 200, body: body} = _response) do
    body
    |> Jason.decode!()
    |> get_in(["Realtime Currency Exchange Rate", "5. Exchange Rate"])
    |> String.to_float()
  end

  defp exchange_rate_url(%{from: from, to: to}) when is_binary(from) and is_binary(to) do
    "#{alpha_vantage_base_url()}/query?function=CURRENCY_EXCHANGE_RATE&from_currency=#{from}&to_currency=#{to}&apikey=#{alpha_vantage_api_key()}"
  end

  defp alpha_vantage_base_url, do: Application.get_env(:payment_server, :alpha_vantage_base_url)

  defp alpha_vantage_api_key, do: Application.get_env(:payment_server, :alpha_vantage_api_key)
end
