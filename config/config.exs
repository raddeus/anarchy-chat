import Config

config :logger, :console,
  metadata: [:room_id, :pid]

config :websocket_playground, ecto_repos: [WebsocketPlayground.Repo]
