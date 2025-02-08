defmodule Rescutex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RescutexWeb.Telemetry,
      Rescutex.Repo,
      {DNSCluster, query: Application.get_env(:rescutex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rescutex.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Rescutex.Finch},
      # Start a worker by calling: Rescutex.Worker.start_link(arg)
      # {Rescutex.Worker, arg},
      # Start to serve requests, typically the last entry
      RescutexWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rescutex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RescutexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
