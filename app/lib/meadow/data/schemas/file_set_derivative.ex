defmodule Meadow.Data.Schemas.FileSetDerivative do
  @moduledoc """
  One derivative of a FileSet's preservation file (`file_set_derivatives`):
  a `kind` (pyramid_tiff, poster, playlist, copy, transcription_file, ...) and
  the S3 location it was written to.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "file_set_derivatives" do
    belongs_to :file_set, Meadow.Data.Schemas.FileSet
    field :kind, :string
    field :location, :string
  end

  def changeset(derivative, params) do
    derivative
    |> cast(params, [:kind, :location])
    |> validate_required([:kind])
  end

  @doc "Normalize a `%{kind => location}` map (or list of entries) into entry params"
  def to_params(nil), do: []
  def to_params(list) when is_list(list), do: Enum.map(list, &entry_params/1)

  def to_params(%{} = map) when not is_struct(map),
    do:
      Enum.map(map, fn {kind, location} ->
        %{kind: to_string(kind), location: location(location)}
      end)

  # A derivative location is an S3 URI; anything else is recorded as unknown
  defp location(location) when is_binary(location), do: location
  defp location(_), do: nil

  defp entry_params(%__MODULE__{id: id, kind: kind, location: location}),
    do: %{id: id, kind: kind, location: location}

  defp entry_params(%{} = map) do
    %{
      id: Map.get(map, :id) || Map.get(map, "id"),
      kind: to_string(Map.get(map, :kind) || Map.get(map, "kind")),
      location: location(Map.get(map, :location) || Map.get(map, "location"))
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  @doc "The `%{kind => location}` map for a list of derivatives"
  def to_map(derivatives) when is_list(derivatives),
    do: Map.new(derivatives, &{&1.kind, &1.location})

  def to_map(%{} = map) when not is_struct(map), do: map
  def to_map(_), do: %{}
end
