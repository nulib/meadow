defmodule Meadow.Data.FileSets.ExtractedMetadata do
  @moduledoc """
  Flatten a tool's extracted metadata document (the JSON an EXIF or MediaInfo
  lambda returns) into `file_set_extracted_metadata_entries` rows and rebuild
  it again. Every container and leaf becomes one entry keyed by its path, so
  the round trip is exact, including arrays and numeric types.
  """

  @doc "Entry params for `document`, rooted at `path`"
  def flatten(document, path \\ [])

  def flatten(%{} = map, path) when not is_struct(map) do
    [
      entry(path, "object", nil)
      | Enum.flat_map(map, fn {k, v} -> flatten(v, path ++ [to_string(k)]) end)
    ]
  end

  def flatten(list, path) when is_list(list) do
    children =
      list
      |> Enum.with_index()
      |> Enum.flat_map(fn {v, i} -> flatten(v, path ++ [Integer.to_string(i)]) end)

    [entry(path, "array", nil) | children]
  end

  def flatten(value, path) when is_binary(value), do: [entry(path, "string", value)]

  def flatten(value, path) when is_integer(value),
    do: [entry(path, "integer", Integer.to_string(value))]

  def flatten(value, path) when is_float(value),
    do: [entry(path, "float", Float.to_string(value))]

  def flatten(value, path) when is_boolean(value), do: [entry(path, "boolean", to_string(value))]
  def flatten(nil, path), do: [entry(path, "null", nil)]
  def flatten(value, path), do: [entry(path, "string", inspect(value))]

  defp entry(path, type, value), do: %{path: path, value_type: type, value: value}

  @doc "Rebuild the document from entries (structs or params). Returns nil when there are no entries."
  def unflatten([]), do: nil

  def unflatten(entries) do
    by_parent = Enum.group_by(entries, &Enum.drop(path_of(&1), -1))

    case Enum.find(entries, &(path_of(&1) == [])) do
      nil -> nil
      root -> build(root, by_parent)
    end
  end

  defp build(entry, by_parent) do
    case type_of(entry) do
      "object" ->
        entry |> children(by_parent) |> Map.new(&{List.last(path_of(&1)), build(&1, by_parent)})

      "array" ->
        entry
        |> children(by_parent)
        |> Enum.sort_by(&String.to_integer(List.last(path_of(&1))))
        |> Enum.map(&build(&1, by_parent))

      "string" ->
        value_of(entry)

      "integer" ->
        String.to_integer(value_of(entry))

      "float" ->
        entry |> value_of() |> Float.parse() |> elem(0)

      "boolean" ->
        value_of(entry) == "true"

      "null" ->
        nil
    end
  end

  defp children(entry, by_parent) do
    path = path_of(entry)
    by_parent |> Map.get(path, []) |> Enum.reject(&(path_of(&1) == path))
  end

  defp path_of(%{path: path}), do: path
  defp path_of(%{"path" => path}), do: path
  defp type_of(%{value_type: type}), do: type
  defp type_of(%{"value_type" => type}), do: type
  defp value_of(%{value: value}), do: value
  defp value_of(%{"value" => value}), do: value

  @doc """
  The image or video dimensions and duration a tool document reports:
  `%{width, height, duration_ms}` (any may be nil).
  """
  def dimensions("exif", %{"value" => %{} = value}) do
    %{width: to_int(value["ImageWidth"]), height: to_int(value["ImageHeight"]), duration_ms: nil}
  end

  def dimensions("mediainfo", %{"value" => %{"media" => %{"track" => tracks}}})
      when is_list(tracks) do
    general = Enum.at(tracks, 0) || %{}
    video = Enum.at(tracks, 1) || %{}

    %{
      width: to_int(video["Width"]),
      height: to_int(video["Height"]),
      duration_ms: duration_ms(general["Duration"])
    }
  end

  def dimensions(_tool, _document), do: %{width: nil, height: nil, duration_ms: nil}

  defp to_int(value) when is_integer(value), do: value
  defp to_int(value) when is_float(value), do: trunc(value)

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp to_int(_), do: nil

  defp duration_ms(value) when is_number(value), do: value * 1000.0

  defp duration_ms(value) when is_binary(value) do
    case Float.parse(value) do
      {seconds, _} -> seconds * 1000
      :error -> nil
    end
  end

  defp duration_ms(_), do: nil
end
