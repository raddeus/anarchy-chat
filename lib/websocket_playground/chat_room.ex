defmodule WebsocketPlayground.ChatRoom do
  use GenServer
  require Logger

  @registry WebsocketPlayground.ChatRoom.Registry
  @supervisor WebsocketPlayground.ChatRoom.Supervisor

  def start(room_id) do
    DynamicSupervisor.start_child(@supervisor, {__MODULE__, [
      room_id: room_id,
      name: {:via, Registry, {@registry, room_id}}
    ]})
  end

  def lookup(room_id) do
    case Registry.lookup(@registry, room_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def get_state(room_id) do
    case lookup(room_id) do
      {:ok, pid} ->
        GenServer.call(pid, :get_state)
      err -> err
    end
  end

  def get_all() do
    Registry.select(@registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do


    # messages_table |> IO.inspect()

    state = %{
      messages: Keyword.get(opts, :messages, []),
      room_id: Keyword.fetch!(opts, :room_id),

      names: %{},
      refs: %{},
    }

    if :ets.whereis(:chat_room_messages) === :undefined do
      :ets.new(:chat_room_messages, [:set, :public, :named_table])
    end
    :ets.lookup(:chat_room_messages, state.room_id) |> IO.inspect()


    schedule_persist_messages()
    {:ok, state}
  end

  @impl true
  def handle_cast({:broadcast_message, content, connection}, state) do
    Logger.info("Received handle_cast for :broadcast_message. Broadcasting to entire room.")
    if content === "!crash" do
      raise("Crashing due to receiving !crash command")
    end

    %{username: username} = :sys.get_state(connection) |> elem(1)

    message = %{
      sender: username,
      content: content,
      room: state.room_id,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    }
    #WebsocketPlayground.Repo.insert!(message)

    # Process.send(connection, :get_state, []) |> IO.inspect()

    Registry.WebsocketConnections
    |> Registry.dispatch(state.room_id, fn(entries) ->
      for {pid, _state} <- entries do
          payload = {
            :broadcast_message,
            message
          }
          Process.send(pid, payload, [])
      end
    end)
    {:noreply, %{state | messages: state.messages ++ [message]}}
  end

  @impl true
  def handle_cast({:add_connection, pid}, state) do
    Logger.info("Got call to add connection: " <> inspect(pid))
    # @TODO - determine behavior when the same connection is added multiple times
    ref = Process.monitor(pid)
    refs = Map.put(state.refs, ref, pid)
    {:noreply, %{state | refs: refs}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {pid, refs} = Map.pop(state.refs, ref) |> IO.inspect()
    Logger.info("Connection closed: " <> inspect(pid) <> ", removing from room: " <> inspect(self()))
    {:noreply, %{state | refs: refs }}
  end
  def handle_info(:persist_messages, state) do
    Logger.info("[Room #{state.room_id}] Persisting all messages...");
    WebsocketPlayground.Schemas.Message
    |> WebsocketPlayground.Repo.insert_all(state.messages)
    Logger.info("[Room #{state.room_id}] Done persisting messages...");
    schedule_persist_messages()
    {:noreply, %{state | messages: []}}
  end
  defp schedule_persist_messages() do
    Process.send_after(self(), :persist_messages, 20000)
  end

  @impl true
  def handle_call(:user_count, _from, state) do
    {:reply, map_size(state.refs), state}
  end


end
