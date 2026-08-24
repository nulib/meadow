defmodule Meadow.Data.Schemas.JSONEncoders do
  @moduledoc """
  Helper functions for encoding Ecto schemas to JSON, handling NotLoaded associations.
  """

  alias Ecto.Association.NotLoaded
  alias Meadow.Data.Schemas.{FileSetDerivative, FileSetExtractedMetadata}

  # Storage bookkeeping on metadata child rows that is not part of the value
  @hidden_keys [:__meta__, :work, :work_id, :position]

  # A controlled entry's identity is its term and role; the row's uuid is only a
  # technical primary key and is not part of the public value.
  @hidden_by_struct %{Meadow.Data.Schemas.ControlledMetadataEntry => [:id, :field]}

  def prep_struct(struct, protocol) do
    hidden = @hidden_keys ++ Map.get(@hidden_by_struct, struct.__struct__, [])

    struct
    |> Map.from_struct()
    |> Enum.reject(fn {key, _} -> key in hidden end)
    |> Enum.map(fn
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
  FileSetAnnotation,
  FileSetCoreMetadata,
  FileSetStructuralMetadata,
  FileSet,
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
    FileSetAnnotation,
    FileSetCoreMetadata,
    FileSetStructuralMetadata,
    FileSet,
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
    FileSetAnnotation,
    FileSetCoreMetadata,
    FileSetStructuralMetadata,
    FileSet,
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
