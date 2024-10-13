defmodule Newsticker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NewstickerWeb.Telemetry,
      Newsticker.Repo,
      {DNSCluster, query: Application.get_env(:newsticker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Newsticker.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Newsticker.Finch},
      # Start a worker by calling: Newsticker.Worker.start_link(arg)
      # {Newsticker.Worker, arg},
      # Start to serve requests, typically the last entry
      {Oban,
       AshOban.config(
         Application.fetch_env!(:newsticker, :ash_domains),
         Application.fetch_env!(:newsticker, Oban)
       )},
      NewstickerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Newsticker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NewstickerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
