defmodule GraylogPublisherTest do
  use ExUnit.Case
  doctest GraylogPublisher

  test "greets the world" do
    assert GraylogPublisher.hello() == :world
  end
end
