defmodule PaymentServer.Tasks.ExchangeRate do
  @moduledoc """
  ExhangeRate Task module
  """
  @spec request_exchange_rate(%{:from => any, :to => any, optional(any) => any}) :: Task.t()
  def request_exchange_rate(%{from: _from, to: _to} = params) do
    Task.Supervisor.async_nolink(
      PaymentServer.TaskSupervisor,
      fn ->
        params
        |> exchange_rate_url()
        |> HTTPoison.get()
      end
    )
  end

  @spec get_exchange_rate_response(Task.t()) :: any
  def get_exchange_rate_response(%Task{} = request) do
    Task.await(request)
  end

  @exchange_rate_key ["Realtime Currency Exchange Rate", "5. Exchange Rate"]

  @spec get_exchange_rate({:error, HTTPoison.Response.t()} | {:ok, HTTPoison.Response.t()}) ::
          {:error, <<_::72>> | Jason.DecodeError.t()} | {:ok, float}
  def get_exchange_rate({:ok, %HTTPoison.Response{status_code: 200, body: body} = _response}) do
    with {:ok, decoded_body} <- Jason.decode(body),
         exchange_rate when not is_nil(exchange_rate) <-
           get_in(decoded_body, @exchange_rate_key) do
      {:ok, String.to_float(exchange_rate)}
    else
      _ ->
        {:error, "API error"}
    end
  end

  def get_exchange_rate(_) do
    {:error, "API error"}
  end

  defp exchange_rate_url(%{from: from, to: to}) when is_binary(from) and is_binary(to) do
    "#{alpha_vantage_base_url()}/query?function=CURRENCY_EXCHANGE_RATE&from_currency=#{from}&to_currency=#{to}&apikey=#{alpha_vantage_api_key()}"
  end

  defp alpha_vantage_base_url, do: Application.get_env(:payment_server, :alpha_vantage_base_url)

  defp alpha_vantage_api_key, do: Application.get_env(:payment_server, :alpha_vantage_api_key)
end
