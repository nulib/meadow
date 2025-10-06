defmodule Meadow.Data.Schemas.ControlledMetadataEntry do
  @moduledoc """
  Schema for Controlled Entry with Role qualifier
  """

  @derive {Jason.Encoder, only: [:role, :term]}
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

  def changeset_with_role(metadata, params) do
    metadata
    |> cast(params, [:role, :term])
    |> validate_required([:term, :role])
  end

  def from_string(value) when is_binary(value) do
    String.split(value, ":", parts: 2)
    |> from_string_result()
  end

  # An unqualified string is just a bare term
  defp from_string_result([term | []]), do: %{term: %{id: term}}

  # A 3-character qualifier indicates a MARC Relator code
  defp from_string_result([<<qualifier::binary-size(3)>> | [term]]),
    do: %{role: %{id: qualifier, scheme: "marc_relator"}, term: %{id: term}}

  # If the term can't be parsed as a URI, assume the qualifier was actually part of the term
  defp from_string_result([qualifier | [term | []]] = value) do
    case URI.parse(term) do
      %{scheme: nil} -> %{term: %{id: Enum.join(value, ":")}}
      _ -> %{role: %{id: qualifier, scheme: "subject_role"}, term: %{id: term}}
    end
  end
end
