defmodule Meadow.Utils.Hush.Transformer.CastTest do
  use ExUnit.Case
  alias Meadow.Utils.Hush.Transformer.Cast, as: Subject

  test "key/0" do
    assert Subject.key() == :cast
  end

  describe "transform/2" do
    test "nil" do
      assert Subject.transform(:atom, nil) == {:ok, nil}
      assert Subject.transform(:binary, nil) == {:ok, nil}
      assert Subject.transform(:boolean, nil) == {:ok, nil}
      assert Subject.transform(:float, nil) == {:ok, nil}
      assert Subject.transform(:integer, nil) == {:ok, nil}
    end

    test "binary" do
      assert Subject.transform(:binary, 123) == {:ok, "123"}
      assert Subject.transform(:binary, "value") == {:ok, "value"}
      assert Subject.transform(:binary, true) == {:ok, "true"}
      assert Subject.transform(:binary, :value) == {:ok, "value"}
    end

    test "integer" do
      assert Subject.transform(:integer, 123) == {:ok, 123}
      assert Subject.transform(:integer, "123") == {:ok, 123}
      assert {:error, _} = Subject.transform(:integer, "123.45")
      assert {:error, _} = Subject.transform(:integer, :value)
      assert {:error, _} = Subject.transform(:integer, "value")
    end

    test "boolean" do
      assert Subject.transform(:boolean, true) == {:ok, true}
      assert Subject.transform(:boolean, false) == {:ok, false}
      assert Subject.transform(:boolean, "true") == {:ok, true}
      assert Subject.transform(:boolean, "false") == {:ok, false}
      assert Subject.transform(:boolean, true) == {:ok, true}
      assert Subject.transform(:boolean, false) == {:ok, false}
    end

    test "float" do
      assert Subject.transform(:float, 123) == {:ok, 123.0}
      assert Subject.transform(:float, "123.45") == {:ok, 123.45}
      assert {:error, _} = Subject.transform(:float, "123")
      assert {:error, _} = Subject.transform(:float, :value)
      assert {:error, _} = Subject.transform(:float, "value")
    end

    test "atom" do
      assert Subject.transform(:atom, :value) == {:ok, :value}
      assert Subject.transform(:atom, "value") == {:ok, :value}
      assert Subject.transform(:atom, true) == {:ok, true}
      assert Subject.transform(:atom, 123.45) == {:ok, :"123.45"}
      assert Subject.transform(:atom, 123) == {:ok, :"123"}
      assert {:error, _} = Subject.transform(:atom, "fhqwhgads")
    end
  end
end
