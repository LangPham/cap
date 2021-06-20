defmodule CapTest do
  use ExUnit.Case
  doctest Cap

  test "greets the world" do
    assert Cap.hello() == :world
  end
end
