defmodule WebsocketPlayground.WebsocketHandler do
  require Logger

  @behaviour :cowboy_websocket

  def init(request, _state) do
    state = %{
      registry_key: request.path,
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
      |> Registry.register(state.registry_key, {})

      {:ok, state}
    end
  end

  def websocket_handle({:text, json}, state) do
    payload = Jason.decode!(json)
    message = payload["data"]["message"]

    Registry.WebsocketConnections
    |> Registry.dispatch(state.registry_key, fn(entries) ->
      for {pid, _} <- entries do
        if pid != self() do
          Process.send(pid, message, [])
        end
      end
    end)

    {:reply, {:text, message}, state}
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
