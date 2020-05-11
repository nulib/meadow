defmodule Meadow.Data.Schemas.Collection do
  @moduledoc """
  Collections are used to group objects for display
  """
  use Ecto.Schema
  use Meadow.Constants

  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "collections" do
    field :name, :string
    field :description, :string
    field :keywords, {:array, :string}, default: []
    field :featured, :boolean
    field :finding_aid_url, :string
    field :admin_email, :string
    field :published, :boolean, default: false

    timestamps()

    belongs_to :representative_work, Work, on_replace: :nilify
    has_many :works, Work

    field :representative_image, :string, virtual: true
  end

  def changeset(collection, params \\ %{}) do
    collection
    |> cast(params, [
      :admin_email,
      :description,
      :featured,
      :finding_aid_url,
      :keywords,
      :name,
      :published,
      :representative_work_id
    ])
    |> assoc_constraint(:representative_work)
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Collection do
    def id(collection), do: collection.id
    def routing(_), do: false

    def encode(collection) do
      %{
        model: %{application: "Meadow", name: "Collection"},
        title: collection.name,
        published: collection.published,
        create_date: collection.inserted_at,
        modified_date: collection.updated_at,
        visibility: "OPEN",
        visibility_term: %{id: "OPEN", label: "Public"},
        representative_image:
          case collection.representative_work do
            nil ->
              %{}

            work ->
              %{
                work_id: work.id,
                url: work.representative_image
              }
          end
      }
    end
  end
end
