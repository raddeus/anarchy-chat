defmodule WebsocketPlayground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {WebsocketPlayground.Repo, [show_sensitive_data_on_connection_error: true]},
      {WebsocketPlayground.MessageStore, []},
      {Registry, keys: :duplicate, name: Registry.WebsocketConnections}, # TODO - naming? WebsocketPlayground.WebsocketConnectionRegistry?
      {Registry, keys: :unique, name: WebsocketPlayground.ChatRoom.Registry},
      {
        DynamicSupervisor,
        name: WebsocketPlayground.ChatRoom.Supervisor,
        strategy: :one_for_one,
        max_restarts: 100,
        max_seconds: 1
      },
      {Plug.Cowboy, scheme: :http, plug: nil, options: [
        dispatch: dispatch(),
        port: String.to_integer(Application.fetch_env!(:websocket_playground, :port))
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
