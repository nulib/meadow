defmodule Meadow.Ingest.MapListTest do
  use ExUnit.Case

  defmodule Age do
    defstruct [:name, :age]
  end

  alias Meadow.Ingest.MapListTest.Age
  alias Meadow.Utils.MapList

  setup do
    {:ok,
     %{
       list: [
         %{name: "Dennis", age: 37},
         %{name: "Regina", age: 19}
       ],
       atomized_list: [
         %{name: :Dennis, age: 37},
         %{name: :Regina, age: 19}
       ],
       struct_list: [
         %Age{name: "Dennis", age: 37},
         %Age{name: "Regina", age: 19}
       ],
       map: %{Dennis: 37, Regina: 19},
       stringified_map: %{"Dennis" => 37, "Regina" => 19}
     }}
  end

  test "get an existing value", context do
    assert(MapList.get(context.list, :name, :age, :Dennis) == 37)
  end

  test "get a missing value", context do
    assert(MapList.get(context.list, :name, :age, "Frank") == nil)
  end
end
