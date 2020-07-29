defmodule Meadow.Data.Schemas.RelatedURLEntry do
  @moduledoc """
  Schema for Related URL
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key false
  embedded_schema do
    field :url, :string
    field :label, Types.CodedTerm
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:url, :label])
    |> validate_required([:url, :label])
  end
end
