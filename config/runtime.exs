import Config

config :logger, :console,
  metadata: [:room_id, :pid]

config :websocket_playground, ecto_repos: [WebsocketPlayground.Repo]

config :websocket_playground, WebsocketPlayground.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  port: System.get_env("DB_PORT", "5432"),
  ssl: true,
  ssl_opts: [
    certfile: "priv/cert.crt"
  ],
  log: false,
  pool_size: 10
