defmodule Meadow.Data.Schemas.Collection do
  @moduledoc """
  Collections are used to group objects for display
  """
  use Ecto.Schema
  use Meadow.Constants

  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Types

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "collections" do
    field(:admin_email, :string)
    field(:description, :string)
    field(:featured, :boolean)
    field(:finding_aid_url, :string)
    field(:keywords, {:array, :string}, default: [])
    field(:title, :string)

    field(:published, :boolean, default: false)
    field(:visibility, Types.CodedTerm)

    timestamps()

    belongs_to(:representative_work, Work, on_replace: :nilify)
    has_many(:works, Work)

    field(:representative_image, :string, virtual: true)
  end

  def changeset(collection, params \\ %{}) do
    collection
    |> cast(params, [
      :id,
      :admin_email,
      :description,
      :featured,
      :finding_aid_url,
      :keywords,
      :title,
      :published,
      :representative_work_id,
      :visibility
    ])
    |> assoc_constraint(:representative_work)
    |> validate_required([:title])
    |> unique_constraint(:title)
  end

  def required_index_preloads, do: [:representative_work]
end
