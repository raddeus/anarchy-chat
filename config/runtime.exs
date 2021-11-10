import Config
import Dotenvy

source([".env", ".env.#{config_env()}", ".env.#{config_env()}.local"])

config :logger, :console,
  metadata: [:room_id, :pid]

config :websocket_playground, ecto_repos: [WebsocketPlayground.Repo]

config :websocket_playground, WebsocketPlayground.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: env!("DB_USER", :string),
  password: env!("DB_PASSWORD", :string),
  database: env!("DB_NAME", :string),
  hostname: env!("DB_HOST", :string),
  port: env!("DB_PORT", :integer),
  ssl: env!("DB_SSL", :boolean),
  log: false,
  pool_size: 10

config :websocket_playground, port: env!("PORT", :integer)
