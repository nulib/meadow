defmodule Meadow.IIIF.V3.Generator do
  @moduledoc """
  Generates resources in accordance with the IIIF Presentation API 2.x
  based on the encoding defined in the schema
  """
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.{Collection, Work}
  alias Meadow.IIIF.V3.Resource

  import Ecto.Query, warn: false

  def create_manifest(%Work{id: id}) do
    id
    |> Works.with_file_sets()
    |> encode!()
  end

  def create_collection(%Collection{id: id}) do
    id
    |> Collections.with_works_and_file_sets()
    |> encode!()
  end

  defp encode!(object) do
    object
    |> Resource.encode()
    |> to_json()
    |> Jason.encode!(pretty: true)
  end

  defp to_json(manifest) when is_struct(manifest),
    do: manifest |> Map.from_struct() |> to_json()

  defp to_json(manifest) do
    manifest
    |> Enum.map(&set_property/1)
    |> Enum.filter(&filter_property/1)
    |> Enum.into(%{})
  end

  defp set_property({:context, value}), do: {"@context", value}
  # defp set_property({:id, value}), do: {"@id", value}
  # defp set_property({:type, value}), do: {"@type", value}

  defp set_property({key, elements}) when is_list(elements) do
    {key, Enum.map(elements, &elem(set_property({key, &1}), 1))}
  end

  defp set_property({key, map = %{}}) do
    {key, to_json(map)}
  end

  defp set_property({_, nil}), do: nil
  defp set_property(tuple), do: tuple

  defp filter_property(nil), do: false
  defp filter_property({:sequences, _}), do: true
  defp filter_property({:canvases, _}), do: true
  defp filter_property({_, []}), do: false
  defp filter_property({_, nil}), do: false
  defp filter_property(_), do: true
end
