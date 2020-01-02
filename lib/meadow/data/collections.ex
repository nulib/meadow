defmodule Meadow.Data.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.Collection
  alias Meadow.Repo

  def list_collections do
    Repo.all(Collection)
  end

  def get_collection!(id), do: Repo.get!(Collection, id)

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def create_collection(attrs \\ %{}) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end
end
