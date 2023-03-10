defmodule PaymentServer.AlphaVantageClient.MockController do
  use Plug.Router
  plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Jason

  plug :match
  plug :dispatch

  get "/query" do
    success(conn)
  end

  defp success(conn) do
    from_currency = conn.query_params["from_currency"]
    to_currency = conn.query_params["to_currency"]

    Plug.Conn.send_resp(
      conn,
      200,
      Jason.encode!(%{
        "Realtime Currency Exchange Rate" => %{
          "1. From_Currency Code" => from_currency,
          "2. From_Currency Name" => "From currency name",
          "3. To_Currency Code" => to_currency,
          "4. To_Currency Name" => "To currency name",
          "5. Exchange Rate" => "0.89",
          "6. Last Refreshed" => DateTime.to_string(DateTime.now!("Etc/UTC")),
          "7. Time Zone" => "UTC",
          "8. Bid Price" => "0.89",
          "9. Ask Price" => "0.89"
        }
      })
    )
  end
end
