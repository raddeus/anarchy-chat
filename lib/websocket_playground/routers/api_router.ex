defmodule WebsocketPlayground.Routers.ApiRouter do
  use Plug.Router
  import Ecto.Query
  plug CORSPlug
  plug :match
  plug :dispatch

  get "/rooms" do
    genserver_rooms = Enum.map(
      WebsocketPlayground.ChatRoom.get_all(),
      fn ({roomId, pid, _}) ->
        %{
          id: roomId,
          pid: inspect(pid),
          user_count: GenServer.call(pid, :user_count),
        }
      end
    )

    {:ok, result} = WebsocketPlayground.Repo.query(
      "SELECT room as id, COUNT(*) as message_count FROM messages GROUP BY room",
      []
    )
    columns = result.columns |> Enum.map(&String.to_atom(&1))
    db_rooms = Enum.map(result.rows, fn(row) ->
      Enum.zip(columns, row)
        |> Map.new
    end)

    rooms = Enum.group_by(genserver_rooms ++ db_rooms, &Map.get(&1, :id))
    |> Enum.map(fn {_, l} ->
      Enum.concat(l)
      |> Enum.into(%{})
    end)

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

      messages_from_genserver = WebsocketPlayground.MessageStore.get_messages(room_id)

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
