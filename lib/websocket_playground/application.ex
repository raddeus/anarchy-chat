defmodule WebsocketPlayground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: WebsocketPlayground.Worker.start_link(arg)
      {Plug.Cowboy, scheme: :http, plug: WebsocketPlayground.Routers.MainRouter, options: [port: 4000]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebsocketPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
