defmodule PaymentServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, args) do
    defaults = [
      # Start the Ecto repository
      PaymentServer.Repo,
      # Start the Telemetry supervisor
      PaymentServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PaymentServer.PubSub},
      # Start the Endpoint (http/https)
      PaymentServerWeb.Endpoint,
      {Absinthe.Subscription, PaymentServerWeb.Endpoint},
      PaymentServer.ExchangeRateSubscriptionServer,
      {Task.Supervisor, name: PaymentServer.TaskSupervisor}
      # Start a worker by calling: PaymentServer.Worker.start_link(arg)
      # {PaymentServer.Worker, arg}
    ]

    children =
      case args do
        [env: :test] -> defaults ++ [{PaymentServer.AlphaVantageClient.MockServer, []}]
        [_] -> defaults ++ []
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PaymentServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PaymentServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
