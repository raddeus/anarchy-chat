defmodule WebsocketPlayground.Routers.MainRouter do
  use Plug.Router

  #plug Plug.Logger
  plug :match
  plug :dispatch

  forward "/public", to: WebsocketPlayground.Handlers.StaticFileHandler
  forward "/api", to: WebsocketPlayground.Routers.ApiRouter

  match _ do
    file = File.read!("priv/static/dist/index.html")
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, file)
  end
end
