defmodule Meadow.TranscriptionBench.Run do
  @moduledoc """
  One press of Run on the transcription bench: the variants as they were sent, the
  file sets and models chosen, and a result for every file set x model x variant.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.TranscriptionBench.Result

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "transcription_bench_runs" do
    field(:name, :string)
    field(:author, :string)
    field(:variants, {:array, :map}, default: [])
    field(:images, {:array, :map}, default: [])
    field(:models, {:array, :string}, default: [])

    field(:total, :integer, virtual: true, default: 0)
    field(:done, :integer, virtual: true, default: 0)
    field(:failed, :integer, virtual: true, default: 0)
    field(:cancelled, :integer, virtual: true, default: 0)
    field(:active, :integer, virtual: true, default: 0)

    has_many(:results, Result, foreign_key: :run_id, preload_order: [asc: :position])

    timestamps()
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:name, :author, :variants, :images, :models])
    |> validate_length(:variants, min: 1)
    |> validate_length(:images, min: 1)
    |> validate_length(:models, min: 1)
  end
end
