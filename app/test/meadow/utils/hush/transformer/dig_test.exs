defmodule Meadow.Utils.Hush.Transformer.DigTest do
  use ExUnit.Case
  alias Meadow.Utils.Hush.Transformer.Dig, as: Subject

  @value %{
    map: %{
      value: 25
    },
    integer: 123,
    string: "value"
  }

  test "key/0" do
    assert Subject.key() == :dig
  end

  test "transform/2" do
    assert Subject.transform([:map, :value], @value) == {:ok, 25}
    assert Subject.transform([:map, :oops], @value) == {:ok, {:error, :not_found}}
    assert Subject.transform([:integer], @value) == {:ok, 123}
    assert Subject.transform([:string], @value) == {:ok, "value"}
    assert Subject.transform([:path], "not accessible") == {:ok, {:error, :not_found}}
  end
end
