defmodule WebsocketPlayground.MessageStore do
  use GenServer

  @table_name :message_store

  def init(arg) do
    :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    {:ok, arg}
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def get_messages(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [] ->
        []
      [{_key, value}] ->
        value
    end
  end

  def add_message(room_id, message) do
    :ets.insert(@table_name, {room_id, get_messages(room_id) ++ [message]})
  end

  def clear_messages(room_id) do
    :ets.delete(@table_name, room_id)
  end
end
