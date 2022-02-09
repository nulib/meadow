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

  def changeset_with_role(metadata, params) do
    metadata
    |> cast(params, [:role, :term])
    |> validate_required([:term, :role])
  end

  def from_string(value) do
    with [qualifier | [term | []]] <- String.split(value, ":", parts: 2) do
      cond do
        URI.parse(term) |> Map.get(:scheme) |> is_nil() ->
          %{term: %{id: value}}

        String.length(qualifier) == 3 ->
          %{role: %{id: qualifier, scheme: "marc_relator"}, term: %{id: term}}

        true ->
          %{role: %{id: qualifier, scheme: "subject_role"}, term: %{id: term}}
      end
    end
  end
end
