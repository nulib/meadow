defmodule Meadow.Data.Schemas.ArkCache do
  @moduledoc """
  Schema for caching ARKs
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:ark, :string, autogenerate: false, read_after_writes: true}
  schema "ark_cache" do
    field(:creator, :string)
    field(:title, :string)
    field(:publisher, :string)
    field(:publication_year, :string)
    field(:resource_type, :string)
    field(:status, :string)
    field(:target, :string)
    field(:work_id, Ecto.UUID)
  end

  def changeset(ark \\ %__MODULE__{}, params)
  def changeset(nil, params), do: changeset(params)

  def changeset(ark, params) do
    cast(ark, params, [
      :ark,
      :creator,
      :title,
      :publisher,
      :publication_year,
      :resource_type,
      :status,
      :target,
      :work_id
    ])
  end
end
