defmodule Meadow.Data.Schemas.ControlledMetadataEntry do
  @moduledoc """
  One controlled-vocabulary entry (term plus optional role qualifier) in a
  work's descriptive metadata (`work_controlled_entries`). `field` names the
  metadata field (subject, creator, ...), `term` is the authority URI and
  `role` is a coded term from the `marc_relator` or `subject_role` scheme.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @fields ~w(contributor creator genre language location style_period subject technique)
  @role_schemes ~w(marc_relator subject_role)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "work_controlled_entries" do
    belongs_to :work, Meadow.Data.Schemas.Work
    field :field, :string
    field :position, :integer
    field :role, Types.CodedTerm, schemes: @role_schemes, source: :role_id
    field :term, Types.ControlledTerm, source: :term_id
  end

  def fields, do: @fields
  def role_schemes, do: @role_schemes

  def changeset(metadata, params, position \\ nil) do
    metadata
    |> cast(params, [:field, :term])
    |> put_position(position)
    |> validate_required([:field, :term])
    |> unique_natural_key([:field, :term])
  end

  def changeset_with_role(metadata, params, position \\ nil) do
    metadata
    |> cast(params, [:field, :term, :role])
    |> put_position(position)
    |> validate_required([:field, :term, :role])
    |> unique_natural_key([:field, :term, :role])
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)

  # The error is keyed by list position (e.g. `subject#40`), so the message
  # names the duplicated term (and role) to make it recognizable
  defp unique_natural_key(changeset, fields) do
    unique_constraint(changeset, fields,
      name: :work_controlled_entries_natural_key,
      message: "#{describe_entry(changeset)} is listed more than once"
    )
  end

  defp describe_entry(changeset) do
    term = changeset |> get_field(:term) |> display_label() |> inspect()

    case get_field(changeset, :role) do
      nil -> term
      role -> "#{term} (#{display_label(role)})"
    end
  end

  defp display_label(%{label: label}) when is_binary(label) and label != "", do: label
  defp display_label(%{id: id}), do: id
  defp display_label(value), do: value

  @doc "Natural identity of an entry or entry params: `{term_id, role_id}`"
  def natural_key(entry) do
    {term_id(Map.get(entry, :term) || Map.get(entry, "term")),
     role_id(Map.get(entry, :role) || Map.get(entry, "role"))}
  end

  def term_id(%{id: id}), do: id
  def term_id(%{"id" => id}), do: id
  def term_id(id) when is_binary(id), do: id
  def term_id(_), do: nil

  def role_id(%{id: id}), do: id
  def role_id(%{"id" => id}), do: id
  def role_id(id) when is_binary(id), do: id
  def role_id(_), do: nil

  @doc "Params for an entry (used when copying entries between works)"
  def to_params(%__MODULE__{id: id, term: term, role: role}) do
    %{id: id, term: term_id(term), role: role && %{id: role.id, scheme: role.scheme}}
  end

  def to_params(%{} = map), do: map

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
