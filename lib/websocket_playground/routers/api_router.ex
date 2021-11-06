defmodule WebsocketPlayground.Routers.ApiRouter do
  use Plug.Router
  import Ecto.Query
  plug CORSPlug
  plug :match
  plug :dispatch

  get "/rooms" do

    rooms = Enum.map(
      WebsocketPlayground.ChatRoom.get_all(),
      fn ({roomId, pid, _}) ->
        #room = Registry.lookup(Registry.WebsocketConnections, roomId)
        #room |> IO.inspect()
        %{
          id: roomId,
          pid: inspect(pid),
          #user_count: Enum.count(Registry.lookup(Registry.WebsocketConnections, roomId))
          user_count: GenServer.call(pid, :user_count)
        }
      end
    )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      rooms: rooms
    }))
  end

  get "/messages" do
    with {:ok, room_id} <- get_room_id(conn) do
      messages_from_db = WebsocketPlayground.Schemas.Message
        |> where([m], m.room == ^room_id)
        |> order_by(desc: :inserted_at)
        |> limit(200)
        |> WebsocketPlayground.Repo.all()
        |> Enum.reverse()

      messages_from_genserver = case WebsocketPlayground.ChatRoom.get_state(room_id) do
        {:ok, room_state} -> room_state.messages
        _err -> []
      end

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{
        messages: messages_from_db ++ messages_from_genserver
      }))
    else _err ->
      conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          message: "Invalid Room ID"
        }))
    end

  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{ message: "Not Found"}))
  end

  defp get_room_id(conn) do
    case conn |> fetch_query_params() do
      %{query_params: %{"room_id" => room_id}} ->
        {:ok, room_id}
      _ ->
        {:error, :no_match}
    end
  end
end
