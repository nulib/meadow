defmodule Meadow.Data.Fields do
  @moduledoc """
  The Fields context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.Field
  alias Meadow.Repo

  @doc """
  Returns the list of Field information.

  ## Examples

      iex> Fields.describe()
      [%field{}, ...]

  """
  def describe(id) do
    Field
    |> Repo.get!(id)
  end

  def describe do
    Field
    |> Repo.all()
  end
end
