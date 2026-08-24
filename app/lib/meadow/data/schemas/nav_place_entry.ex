defmodule Meadow.Data.Schemas.NavPlaceEntry do
  @moduledoc """
  One `nav_place` entry on a work: a GeoNames place id, label, optional summary
  and a point coordinate.

  Places are embedded in the `nav_place` jsonb column of
  `work_descriptive_metadata` rather than stored as rows: they carry no foreign
  key, are never queried relationally, and cannot be batch updated or proposed
  by a plan change, so a table would buy nothing. List order is the jsonb array
  order, so there is no `position`.

  The public shape is the concise map
  `%{"id", "label", "summary", "coordinates" => [lon, lat]}` produced by the CSV
  importer.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :place_id, :string
    field :label, :string
    field :summary, :string
    field :longitude, :float
    field :latitude, :float
  end

  def changeset(entry, params) do
    entry
    |> cast(to_params(params), [:place_id, :label, :summary, :longitude, :latitude])
    |> validate_place()
  end

  # A place needs at least something to identify it
  defp validate_place(changeset) do
    if Enum.any?([:place_id, :label, :longitude], &get_field(changeset, &1)),
      do: changeset,
      else: add_error(changeset, :place_id, "can't be blank")
  end

  @doc "Convert the concise GeoJSON-ish map into entry params"
  def to_params(%__MODULE__{} = entry),
    do: Map.take(entry, [:place_id, :label, :summary, :longitude, :latitude])

  def to_params(%{} = map) do
    map = Map.new(map, fn {k, v} -> {to_string(k), v} end)

    case Map.fetch(map, "place_id") do
      {:ok, _} ->
        %{
          place_id: map["place_id"],
          label: map["label"],
          summary: map["summary"],
          longitude: map["longitude"],
          latitude: map["latitude"]
        }

      :error ->
        {lon, lat} = coordinates(map["coordinates"])

        %{
          place_id: map["id"],
          label: map["label"],
          summary: map["summary"],
          longitude: lon,
          latitude: lat
        }
    end
  end

  def to_params(other), do: other

  defp coordinates([lon, lat | _]) when is_number(lon) and is_number(lat), do: {lon, lat}
  defp coordinates(_), do: {nil, nil}

  @doc "The concise public map for an entry"
  def to_map(%__MODULE__{} = entry) do
    %{}
    |> maybe_put("id", entry.place_id)
    |> maybe_put("label", entry.label)
    |> maybe_put("coordinates", coordinates_of(entry))
    |> maybe_put("summary", entry.summary)
  end

  def to_map(%{} = map), do: map

  defp coordinates_of(%{longitude: lon, latitude: lat}) when is_number(lon) and is_number(lat),
    do: [lon, lat]

  defp coordinates_of(_), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
