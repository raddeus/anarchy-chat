defmodule WebsocketPlaygroundTest do
  use ExUnit.Case
  doctest WebsocketPlayground

  test "can view stats" do
    assert WebsocketPlayground.stats() == :todo_return_stats
  end
end
