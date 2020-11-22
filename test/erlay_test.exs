defmodule ErlayTest do
  use ExUnit.Case
  doctest Erlay

  test "greets the world" do
    assert Erlay.hello() == :world
  end
end
