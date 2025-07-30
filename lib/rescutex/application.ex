defmodule Rescutex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        RescutexWeb.Telemetry,
        Rescutex.Repo,
        {Oban, Application.fetch_env!(:rescutex, Oban)},
        {DNSCluster, query: Application.get_env(:rescutex, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Rescutex.PubSub},
        {Finch, name: Rescutex.Finch},
        # Rescutex.AI.Worker,
        RescutexWeb.Endpoint
      ] ++
        children(config_env())

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

  defp children(:test), do: []
  defp children(_), do: [{Goth, name: Rescutex.Goth}]

  defp config_env do
    Application.get_env(:rescutex, :current_env)
  end
end
