defmodule Meadow.Data.Schemas.WorkEmbedding do
  @moduledoc """
  The stored text embedding for a Work (one row per work).

  `text_hash` identifies the exact prompt the vector was generated from, so an
  unchanged work is never embedded twice; `model` records which model produced
  it, so vectors from different models are never mixed in the search index.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work

  @primary_key false
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "work_embeddings" do
    belongs_to(:work, Work, primary_key: true)
    field(:model, :string)
    field(:text_hash, :string)
    field(:text_length, :integer)
    field(:embedding, Pgvector.Ecto.Vector)
    timestamps()
  end

  @fields ~w(model text_hash text_length embedding)a

  @doc """
  Changeset for a work's embedding. `work_id` is set on the struct by the
  caller and is never cast.
  """
  def changeset(%__MODULE__{} = embedding, attrs) do
    embedding
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:work_id)
  end

  @doc "The embedding as a plain list of floats"
  def to_list(%__MODULE__{embedding: embedding}), do: Pgvector.to_list(embedding)
end
