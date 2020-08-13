defmodule Meadow.Utils.StructMapTest do
  use ExUnit.Case
  alias Meadow.Utils.StructMap

  defstruct struct: nil,
            map: nil,
            list: nil,
            boolean: nil,
            number: nil,
            string: nil,
            atom: nil,
            tuple: nil

  describe "Meadow.Utils.StructMap" do
    test "deep_struct_to_map/1" do
      inner_struct = %__MODULE__{struct: nil, map: %{a: 1, b: 2}, list: [1, 2, 3]}

      inner_map = %{
        struct: nil,
        map: %{a: 1, b: 2},
        list: [1, 2, 3],
        atom: nil,
        boolean: nil,
        number: nil,
        string: nil,
        tuple: nil
      }

      input = %__MODULE__{
        struct: inner_struct,
        map: %{struct: inner_struct, scalar: "Scalar"},
        list: [inner_struct, "Scalar"],
        boolean: true,
        number: 1234,
        string: "String",
        atom: :atom,
        tuple: {inner_struct, 2, 3}
      }

      assert StructMap.deep_struct_to_map(input) == %{
               struct: inner_map,
               map: %{
                 struct: inner_map,
                 scalar: "Scalar"
               },
               list: [inner_map, "Scalar"],
               boolean: true,
               number: 1234,
               string: "String",
               atom: :atom,
               tuple: {inner_map, 2, 3}
             }
    end
  end
end
