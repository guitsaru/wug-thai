defmodule Wug.ThaiTest do
  use ExUnit.Case
  doctest Wug.Thai

  test "greets the world" do
    assert Wug.Thai.hello() == :world
  end
end
