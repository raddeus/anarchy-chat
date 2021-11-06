defmodule WebsocketPlayground.WebsocketHandler do
  require Logger

  @behaviour :cowboy_websocket

  @room_registry Registry.WebsocketConnections

  def init(request, _state) do
    [room_id | _] = request.path_info
    %{"username" => username} = URI.decode_query(request.qs)
    state = %{
      room_id: room_id,
      authorized: String.length(username) > 3 && String.length(username) < 25,
      username: username,
    }

    {:cowboy_websocket, request, state, %{
      idle_timeout: 1000 * 60 * 15
    }}
  end

  def websocket_init(state) do
    if !state.authorized do
      Logger.debug("Websocket connection closed in _init_ due to being unauthorized.")

      {:reply, {:close, 1000, "reason"}, state}
    else
      Logger.debug("Registering new websocket connection")
      Registry.register(@room_registry, state.room_id, {})
      {:ok, pid} = get_or_create_room(state.room_id)
      GenServer.cast(pid, {:add_connection, self()})
      {:ok, state}
    end
  end

  defp get_or_create_room(room_id) do
    case WebsocketPlayground.ChatRoom.lookup(room_id) do
      {:ok, pid} ->
        Logger.debug("Room already exists")
        {:ok, pid}
      _ ->
        Logger.debug("Creating new room: " <> room_id)
        WebsocketPlayground.ChatRoom.start(room_id)
    end
  end

  def websocket_handle({:text, json}, state) do
    payload = Jason.decode!(json)
    message = payload["data"]["message"]

    case WebsocketPlayground.ChatRoom.lookup(state.room_id) do
      {:ok, pid} ->
        GenServer.cast(pid, {:broadcast_message, message, self()})
        # {:reply, {:text, message}, state}
        {:ok, state}
      _ ->
        {:reply, {:close, 1000, "reason"}, state}
    end
  end

  def websocket_info({:broadcast_message, %{content: content, sender: sender}}, state) do
    Logger.debug("Got :broadcast_message message. Sending to client...")
    #message |> IO.inspect()
    {:reply, {:text, "#{sender}: #{content}"}, state}
  end

  def websocket_info({:broadcast_system, text}, state) do
    Logger.debug("Got :broadcast_system message. Sending")
    {:ok, state}
  end

  def websocket_info(info, state) do
    Logger.debug("Got websocket_info #{inspect info}")
    {:reply, {:text, info}, state}
  end
end
