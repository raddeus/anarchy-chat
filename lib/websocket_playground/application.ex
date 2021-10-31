defmodule WebsocketPlayground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.WebsocketConnections}, # TODO - naming? WebsocketPlayground.WebsocketConnectionRegistry?
      {Registry, keys: :unique, name: WebsocketPlayground.ChatRoom.Registry},
      {DynamicSupervisor, name: WebsocketPlayground.ChatRoom.Supervisor, strategy: :one_for_one},
      {Plug.Cowboy, scheme: :http, plug: nil, options: [
        dispatch: dispatch(),
        port: 4000
      ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebsocketPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
        [
          {"/ws/[...]", WebsocketPlayground.WebsocketHandler, []},
          {:_, Plug.Cowboy.Handler, {WebsocketPlayground.Routers.MainRouter, []}}
        ]
      }
    ]
  end

end
