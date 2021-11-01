defmodule WebsocketPlayground.Routers.ApiRouter do
  use Plug.Router

  plug CORSPlug
  plug :match
  plug :dispatch

  get "/rooms" do
    rooms = Enum.map(
      WebsocketPlayground.ChatRoom.get_all(),
      fn ({roomId, pid, _}) ->
        %{
          id: roomId,
          pid: inspect(pid),
          user_count: Enum.count(Registry.lookup(Registry.WebsocketConnections, roomId))
        }
      end
    )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      rooms: rooms
    }))
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{ message: "Not Found"}))
  end
end
