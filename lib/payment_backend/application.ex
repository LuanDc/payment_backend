defmodule PaymentBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Oban.Telemetry.attach_default_logger(encode: false)

    topologies = [
      default: [
        strategy: Elixir.Cluster.Strategy.Gossip
      ]
    ]

    children = [
      PaymentBackendWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:payment_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PaymentBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PaymentBackend.Finch},
      PaymentBackend.Repo,
      PaymentBackend.ReplicatedCache,
      {Oban, Application.fetch_env!(:payment_backend, Oban)},
      # Start a worker by calling: PaymentBackend.Worker.start_link(arg)
      # {PaymentBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      {Task.Supervisor, name: PaymentBackend.TaskSupervisor},
      PaymentBackend.Payments.PaymentProcessorHealth,
      PaymentBackend.Oban,
      PaymentBackendWeb.Endpoint,
      {Cluster.Supervisor, [topologies, [name: PaymentBackend.ClusterSupervisor]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PaymentBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PaymentBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
