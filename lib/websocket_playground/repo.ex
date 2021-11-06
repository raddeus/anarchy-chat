defmodule WebsocketPlayground.Repo do
  use Ecto.Repo,
    otp_app: :websocket_playground,
    adapter: Ecto.Adapters.Postgres
end
