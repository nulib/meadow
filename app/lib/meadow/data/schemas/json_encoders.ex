defmodule Meadow.Data.Schemas.JSONEncoders do
  @moduledoc """
  Helper functions for encoding Ecto schemas to JSON, handling NotLoaded associations.
  """

  alias Ecto.Association.NotLoaded
  alias Meadow.Data.Schemas.{FileSetDerivative, FileSetExtractedMetadata}

  # Storage bookkeeping on metadata child rows that is not part of the value
  @hidden_keys [:__meta__, :work, :work_id, :section, :field, :position, :role_scheme]

  def prep_struct(struct, protocol) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn
      {key, _} when key in @hidden_keys ->
        nil

      # File set derivative and extracted metadata rows are presented in the
      # `%{kind => location}` / `%{tool => document}` shape they had as jsonb
      {:derivatives, rows} when is_list(rows) ->
        {:derivatives, FileSetDerivative.to_map(rows)}

      {:extracted_metadata, rows} when is_list(rows) ->
        {:extracted_metadata, FileSetExtractedMetadata.to_map(rows)}

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

alias Meadow.Data.Schemas.{
  CodedTerm,
  Collection,
  ControlledMetadataEntry,
  DateCreatedEntry,
  FileSetAnnotation,
  FileSetCoreMetadata,
  FileSetStructuralMetadata,
  FileSet,
  MetadataValue,
  NavPlaceEntry,
  NoteEntry,
  RelatedURLEntry,
  WorkAdministrativeMetadata,
  WorkDescriptiveMetadata,
  Work
}

defimpl Jason.Encoder,
  for: [
    CodedTerm,
    Collection,
    ControlledMetadataEntry,
    DateCreatedEntry,
    FileSetAnnotation,
    FileSetCoreMetadata,
    FileSetStructuralMetadata,
    FileSet,
    MetadataValue,
    NavPlaceEntry,
    NoteEntry,
    RelatedURLEntry,
    WorkAdministrativeMetadata,
    WorkDescriptiveMetadata,
    Work
  ] do
  def encode(struct, opts) do
    struct
    |> Meadow.Data.Schemas.JSONEncoders.prep_struct(Jason.Encoder)
    |> Jason.Encode.map(opts)
  end
end

defimpl JSON.Encoder,
  for: [
    CodedTerm,
    Collection,
    ControlledMetadataEntry,
    DateCreatedEntry,
    FileSetAnnotation,
    FileSetCoreMetadata,
    FileSetStructuralMetadata,
    FileSet,
    MetadataValue,
    NavPlaceEntry,
    NoteEntry,
    RelatedURLEntry,
    WorkAdministrativeMetadata,
    WorkDescriptiveMetadata,
    Work
  ] do
  def encode(struct, encoder) do
    struct
    |> Meadow.Data.Schemas.JSONEncoders.prep_struct(JSON.Encoder)
    |> JSON.Encoder.encode(encoder)
  end
end
