defmodule Meadow.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @work_types ~w[Image Video Audio Document]
      @visibility ~w[public private registered]
    end
  end
end
