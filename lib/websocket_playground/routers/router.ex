defmodule WebsocketPlayground.Routers.MainRouter do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  forward "/public", to: WebsocketPlayground.Handlers.StaticFileHandler
  # get "/" do
  #   page = EEx.eval_file("views/index.html.eex")
  #   conn
  #   |> put_resp_content_type("text/html")
  #   |> send_resp(200, page)
  # end

  # forward "/ws", to: WebsocketPlayground.WebsocketRouter

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end