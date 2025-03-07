defmodule Meadow.Ark.Serializer do
  @moduledoc """
  Helper functions to serialize and deserialize ark values
  """

  @datacite_map %{
    ark: "success",
    creator: "datacite.creator",
    title: "datacite.title",
    publisher: "datacite.publisher",
    publication_year: "datacite.publicationyear",
    resource_type: "datacite.resourcetype",
    status: "_status",
    target: "_target"
  }

  def deserialize(response) do
    field_map =
      Map.values(@datacite_map)
      |> Enum.zip(Map.keys(@datacite_map))
      |> Enum.into(%{})

    struct!(
      Meadow.Ark,
      response
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(fn attribute ->
        [key, value] = String.split(attribute, ": ", parts: 2)
        {Map.get(field_map, key), URI.decode(value)}
      end)
      |> Enum.reject(fn {key, _} -> is_nil(key) end)
    )
  end

  def serialize(%Meadow.Ark{} = ark), do: serialize(Map.from_struct(ark))

  def serialize(ark) when is_map(ark) do
    ark
    |> Enum.sort_by(fn {key, _} -> to_string(key) end)
    |> Enum.reduce(["_profile: datacite"], fn
      {_, nil}, acc -> acc
      {:ark, _}, acc -> acc
      {:work_id, _}, acc -> acc
      entry, acc -> [serialize(entry) | acc]
    end)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  def serialize({key, value}) when is_atom(key) do
    escapable =
      case key do
        :target -> "%\r\n"
        _ -> ":%\r\n"
      end

    [
      Map.get(@datacite_map, key),
      URI.encode(value, fn c -> not String.contains?(escapable, <<c>>) end)
    ]
    |> Enum.join(": ")
  end
end
