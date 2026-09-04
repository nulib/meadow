defmodule Meadow.Data.Schemas.NavPlaceEntry do
  @moduledoc """
  One `nav_place` entry on a work (`work_nav_places`): a GeoNames place id,
  label, optional summary and a point coordinate. The public shape is the
  concise map `%{"id", "label", "summary", "coordinates" => [lon, lat]}`
  produced by the CSV importer.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "work_nav_places" do
    belongs_to :work, Meadow.Data.Schemas.Work
    field :position, :integer
    field :place_id, :string
    field :label, :string
    field :summary, :string
    field :longitude, :float
    field :latitude, :float
  end

  def changeset(entry, params, position \\ nil) do
    entry
    |> cast(to_params(params), [:place_id, :label, :summary, :longitude, :latitude])
    |> put_position(position)
    |> validate_place()
  end

  # A place needs at least something to identify it
  defp validate_place(changeset) do
    if Enum.any?([:place_id, :label, :longitude], &get_field(changeset, &1)),
      do: changeset,
      else: add_error(changeset, :place_id, "can't be blank")
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)

  @doc "Natural identity: the place id, falling back to label and coordinates"
  def natural_key(entry) do
    params = to_params(entry)

    Map.get(params, :place_id) ||
      {Map.get(params, :label), Map.get(params, :longitude), Map.get(params, :latitude)}
  end

  @doc "Convert the concise GeoJSON-ish map into entry params"
  def to_params(%__MODULE__{} = entry),
    do: Map.take(entry, [:id, :place_id, :label, :summary, :longitude, :latitude])

  def to_params(%{} = map) do
    map = Map.new(map, fn {k, v} -> {to_string(k), v} end)

    case Map.fetch(map, "place_id") do
      {:ok, _} ->
        %{
          id: map["id"],
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
