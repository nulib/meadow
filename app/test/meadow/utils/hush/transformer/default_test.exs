defmodule Meadow.Utils.Hush.Transformer.DefaultTest do
  use ExUnit.Case
  alias Meadow.Utils.Hush.Transformer.Default, as: Subject

  test "key/0" do
    assert Subject.key() == :default
  end

  test "transform/2" do
    assert Subject.transform("default", "value") == {:ok, "value"}
    assert Subject.transform("default", nil) == {:ok, nil}
    assert Subject.transform("default", {:error, :not_found}) == {:ok, "default"}
  end
end
