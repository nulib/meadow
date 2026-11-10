defmodule Meadow.Data.Schemas.FileSetEmbedding do
  @moduledoc """
  The stored image embedding for a FileSet (one row per file set).

  The vector lives in the same space as work and query text embeddings.
  `model` records which model produced it and `soft_tokens` the image token
  budget it was generated with.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Data.Schemas.FileSet

  @primary_key false
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "file_set_embeddings" do
    belongs_to(:file_set, FileSet, primary_key: true)
    field(:model, :string)
    field(:soft_tokens, :integer)
    field(:embedding, Pgvector.Ecto.Vector)
    timestamps()
  end

  @fields ~w(model soft_tokens embedding)a

  @doc """
  Changeset for a file set's embedding. `file_set_id` is set on the struct by
  the caller and is never cast.
  """
  def changeset(%__MODULE__{} = embedding, attrs) do
    embedding
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:file_set_id)
  end

  @doc "The embedding as a plain list of floats"
  def to_list(%__MODULE__{embedding: embedding}), do: Pgvector.to_list(embedding)
end
