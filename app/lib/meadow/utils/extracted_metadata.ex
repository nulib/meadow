defmodule Meadow.Utils.ExtractedMetadata do
  @moduledoc """
  Transform extracted metadata for GraphQL / indexing
  """

  alias Meadow.Utils.Exif

  def transform(metadata) when is_map(metadata) do
    metadata
    |> Enum.map(fn {key, data} ->
      case key do
        "exif" -> {key, transform_data(data, &Exif.transform/1)}
        "mediainfo" -> nil
        _ -> {key, data}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  def transform(other), do: other

  defp transform_data("", _), do: %{}

  defp transform_data(data, transformer) do
    with value <- Map.get(data, "value") do
      Map.put(data, "value", transformer.(value))
    end
  end
end
