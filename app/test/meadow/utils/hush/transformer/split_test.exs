defmodule Meadow.Utils.Hush.Transformer.SplitTest do
  use ExUnit.Case
  alias Meadow.Utils.Hush.Transformer.Split, as: Subject

  test "key/0" do
    assert Subject.key() == :split
  end

  test "transform/2" do
    assert Subject.transform(", ", "1, 2,  3") == ["1", "2", " 3"]
    assert Subject.transform(~r/,\s*/, "1,2, 3,  4") == ["1", "2", "3", "4"]
    assert Subject.transform({~r/,\s*/, parts: 2}, "1,2, 3,  4") == ["1", "2, 3,  4"]
    assert Subject.transform(~r/,\s*/, [1, 2, 3]) == [1, 2, 3]
  end
end
