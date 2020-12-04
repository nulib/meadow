defmodule Meadow.Data.Schemas.ControlledMetadataEntry do
  @moduledoc """
  Schema for Controlled Entry with Role qualifier
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key false
  embedded_schema do
    field :role, Types.CodedTerm
    field :term, Types.ControlledTerm
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:role, :term])
    |> validate_required([:term])
  end

  def from_string(value) do
    case value do
      "GEOGRAPHICAL:" <> uri ->
        %{role: %{id: "GEOGRAPHICAL", scheme: "subject_role"}, term: %{id: uri}}

      "TOPICAL:" <> uri ->
        %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: uri}}

      <<prefix::binary-size(3), ":", uri::binary>> ->
        %{role: %{id: prefix, scheme: "marc_relator"}, term: %{id: uri}}

      uri ->
        %{term: %{id: uri}}
    end
  end
end
