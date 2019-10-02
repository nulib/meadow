defmodule Meadow.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @work_types ~w[image audio video document]
      @visibility ~w[open authenticated restricted]
      @file_set_roles ~w[am pm]
    end
  end
end
