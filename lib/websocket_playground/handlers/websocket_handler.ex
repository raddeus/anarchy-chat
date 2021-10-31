defmodule WebsocketPlayground.WebsocketHandler do
  require Logger

  @behaviour :cowboy_websocket

  def init(request, _state) do
    [room_id | _] = request.path_info
    state = %{
      room_id: room_id,
      authorized: request.path !== "unauthorized"
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

      Registry.WebsocketConnections
      |> Registry.register(state.room_id, {})

      case WebsocketPlayground.ChatRoom.lookup(state.room_id) do
        {:ok, _pid} ->
          Logger.debug("Room already exists")
        _ ->
          Logger.debug("Creating new room: " <> state.room_id)
          {:ok, _pid} = WebsocketPlayground.ChatRoom.start(state.room_id)
      end

      {:ok, state}
    end
  end

  def websocket_handle({:text, json}, state) do
    payload = Jason.decode!(json)
    message = payload["data"]["message"]

    case WebsocketPlayground.ChatRoom.lookup(state.room_id) do
      {:ok, pid} ->
        GenServer.cast(pid, {:broadcast_message, message})
        # {:reply, {:text, message}, state}
        {:ok, state}
      _ ->
        {:reply, {:close, 1000, "reason"}, state}
    end
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
