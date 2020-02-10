defmodule Meadow.Data.Schemas.Collection do
  @moduledoc """
  Collections are used to group objects for display
  """
  use Ecto.Schema
  use Meadow.Constants

  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "collections" do
    field :name, :string
    field :description, :string
    field :keywords, {:array, :string}, default: []
    field :featured, :boolean
    field :finding_aid_url, :string
    field :admin_email, :string
    field :published, :boolean, default: false

    timestamps()

    has_many :works, Work
  end

  def changeset(collection, params) do
    collection
    |> cast(params, [
      :name,
      :description,
      :keywords,
      :featured,
      :finding_aid_url,
      :admin_email,
      :published
    ])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Collection do
    def id(collection), do: collection.id
    def routing(_), do: false

    def encode(collection) do
      %{
        model: %{application: "Meadow", name: "Collection"},
        name: collection.name
      }
    end
  end
end
