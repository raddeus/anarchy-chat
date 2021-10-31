defmodule WebsocketPlayground.ChatRoom do
  use GenServer
  require Logger
  @registry WebsocketPlayground.ChatRoom.Registry
  @supervisor WebsocketPlayground.ChatRoom.Supervisor

  def start(room_id) do
    opts = [
      room_id: room_id,
      name: {:via, Registry, {@registry, room_id}}
    ]

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  def lookup(room_id) do
    case Registry.lookup(@registry, room_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    state = %{
      messages: Keyword.get(opts, :messages, []),
      room_id: Keyword.fetch!(opts, :room_id),
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:broadcast_message, message}, state) do
    Logger.info("Received handle_cast for :broadcast_message. Broadcasting to entire room.")
    Registry.WebsocketConnections
    |> Registry.dispatch(state.room_id, fn(entries) ->
      for {pid, _state} <- entries do
          Process.send(pid, message, [])
      end
    end)
    {:noreply, %{state | messages: state.messages ++ [message]}}
  end

end
