defmodule Meadow.Data.Schemas.JSONEncoders do
  @moduledoc """
  Helper functions for encoding Ecto schemas to JSON, handling NotLoaded associations.
  """

  alias Ecto.Association.NotLoaded

  def prep_struct(struct, protocol) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn
      {:__meta__, _} ->
        nil
      {key, %NotLoaded{__cardinality__: :one}} ->
        {key, nil}
      {key, %NotLoaded{__cardinality__: :many}} ->
        {key, []}
      {key, value} ->
        case protocol.impl_for(value) do
           nil -> {key, nil}
           Jason.Encoder.Any -> {key, nil}
           _ -> {key, value}
        end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end
end

alias Meadow.Data.Schemas.{CodedTerm, Collection, ControlledMetadataEntry,
  FileSetAnnotation, FileSetCoreMetadata, FileSetStructuralMetadata, FileSet,
  NoteEntry, RelatedURLEntry, WorkAdministrativeMetadata, WorkDescriptiveMetadata,
  Work}

defimpl Jason.Encoder, for: [CodedTerm, Collection, ControlledMetadataEntry,
  FileSetAnnotation, FileSetCoreMetadata, FileSetStructuralMetadata, FileSet,
  NoteEntry, RelatedURLEntry, WorkAdministrativeMetadata, WorkDescriptiveMetadata,
  Work] do

    def encode(struct, opts) do
    struct
    |> Meadow.Data.Schemas.JSONEncoders.prep_struct(Jason.Encoder)
    |> Jason.Encode.map(opts)
  end
end

defimpl JSON.Encoder, for: [CodedTerm, Collection, ControlledMetadataEntry,
  FileSetAnnotation, FileSetCoreMetadata, FileSetStructuralMetadata, FileSet,
  NoteEntry, RelatedURLEntry, WorkAdministrativeMetadata, WorkDescriptiveMetadata,
  Work] do

    def encode(struct, encoder) do
    struct
    |> Meadow.Data.Schemas.JSONEncoders.prep_struct(JSON.Encoder)
    |> JSON.Encoder.encode(encoder)
  end
end
