defmodule WebsocketPlaygroundTest do
  use ExUnit.Case
  doctest WebsocketPlayground

  test "greets the world" do
    assert WebsocketPlayground.hello() == :world
  end
end
