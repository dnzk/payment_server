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
    |> String.replace(".", "")
    |> String.to_integer()
  end

  defp exchange_rate_url(%{from: from, to: to}) do
    Application.get_env(:payment_server, :alpha_vantage_base_url)
    |> Kernel.<>("/query?function=CURRENCY_EXCHANGE_RATE&from_currency=")
    |> Kernel.<>(to_string(from))
    |> Kernel.<>("&to_currency=")
    |> Kernel.<>(to_string(to))
    |> Kernel.<>("&apikey=demo")
  end
end
