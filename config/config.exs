import Config

config :websocket_playground, ecto_repos: [WebsocketPlayground.Repo]

config :websocket_playground, WebsocketPlayground.Repo,
  database: "chat",
  username: "chat",
  password: "test",
  hostname: "localhost"
