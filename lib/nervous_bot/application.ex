defmodule NervousBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      NervousBotWeb.Telemetry,
      # Start the Ecto repository
      NervousBot.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: NervousBot.PubSub},
      # Start Finch
      {Finch, name: NervousBot.Finch},
      # Start the Endpoint (http/https)
      NervousBotWeb.Endpoint,
      NervousBot.Spacetraders.Api.LiveHttpClient.SessionLogger,
      {Registry, keys: :unique, name: NervousBotMissions.Mining.Registry},
      NervousBotMissions.Missions.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervousBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NervousBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
