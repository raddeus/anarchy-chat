defmodule WebsocketPlayground.ChatRoom do
  use GenServer, restart: :transient
  require Logger
  alias WebsocketPlayground.Schemas.Message
  alias WebsocketPlayground.Repo

  @registry WebsocketPlayground.ChatRoom.Registry
  @supervisor WebsocketPlayground.ChatRoom.Supervisor
  @message_store WebsocketPlayground.MessageStore

  def start(room_id) do
    DynamicSupervisor.start_child(@supervisor, {__MODULE__, [
      room_id: room_id,
      name: {:via, Registry, {@registry, room_id}},
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
    state = %{
      room_id: Keyword.fetch!(opts, :room_id),
      names: %{},
      refs: %{},
    }
    Logger.metadata(room_id: state.room_id)

    GenServer.cast(self(), {:broadcast_system_message, "Room Started: #{inspect self()}"})
    schedule_persist_messages()
    schedule_hibernate()
    {:ok, state}
  end

  @impl true
  def handle_cast({:broadcast_message, content, connection}, state) do
    if content === "!crash" do
      raise("Crashing due to receiving !crash command")
    end

    %{username: username} = :sys.get_state(connection) |> elem(1)

    message = %{
      sender: username,
      content: content,
      room: state.room_id,
      inserted_at: now(),
      updated_at: now(),
    }

    @message_store.add_message(state.room_id, message)

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
    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast_system_message, content}, state) do
    Registry.WebsocketConnections
    |> Registry.dispatch(state.room_id, fn(entries) ->
      for {pid, _state} <- entries do
          payload = {
            :broadcast_message,
            %{
              sender: "SYSTEM",
              content: content,
              room: state.room_id,
              inserted_at: now(),
              updated_at: now(),
            }
          }
          Process.send(pid, payload, [])
      end
    end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_connection, pid}, state) do
    Logger.info("Adding Connection: #{inspect pid}")
    ref = Process.monitor(pid)
    refs = Map.put(state.refs, ref, pid)
    {:noreply, %{state | refs: refs}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call(:user_count, _from, state) do
    {:reply, map_size(state.refs), state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {pid, refs} = Map.pop(state.refs, ref)
    Logger.info("Removing Connection: #{inspect pid}")

    if (map_size(refs) === 0) do
      Logger.debug("No connections left. Hibernating soon...")
      schedule_hibernate()
    end

    {:noreply, %{state | refs: refs }}
  end

  @impl true
  def handle_info(:persist_messages, state) do
    Logger.info("Persisting all messages...");

    ets_messages = @message_store.get_messages(state.room_id)

    Message
    |> Repo.insert_all(ets_messages)

    @message_store.clear_messages(state.room_id)

    Logger.info("Done persisting messages...");
    schedule_persist_messages()
    {:noreply, state}
  end

  @impl true
  def handle_info(:terminate_if_vacant, state) do
    if map_size(state.refs) === 0 do
      Logger.info("Terminating normally due to no activity")
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  defp schedule_persist_messages(send_after \\ 20000) do
    Process.send_after(self(), :persist_messages, send_after)
  end

  defp schedule_hibernate(send_after \\ 20000) do
    Process.send_after(self(), :terminate_if_vacant, send_after)
  end

  defp now() do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end

end
