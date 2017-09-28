defmodule TzWorldTest do
  use ExUnit.Case
  doctest TzWorld

  test "greets the world" do
    assert TzWorld.hello() == :world
  end
end
