defmodule AVR.Migration do
  alias Meadow.Data.Schemas.{Collection, Work}
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Ingest.Rows
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Repo

  import Ecto.Query

  def import_collections do
    collections()
    |> Enum.map(fn collection_attributes ->
      case Repo.get(Collection, collection_attributes.id) do
        nil -> Collections.create_collection(collection_attributes)
        collection -> {:ok, collection}
      end
    end)
  end

  def map_works_to_collections(ingest_sheet_id) do
    with collection_map <- collection_map(),
         work_collections <- work_collections(ingest_sheet_id) do
      stream =
        from(w in Work, where: w.ingest_sheet_id == ^ingest_sheet_id)
        |> Repo.stream()
        |> Stream.each(fn work ->
          "avr:" <> avr_work_id = work.accession_number
          avr_collection = work_collections |> Map.get(avr_work_id)
          meadow_collection = collection_map |> Map.get(avr_collection)
          work |> Works.update_work(%{collection_id: meadow_collection})
        end)

      Repo.transaction(fn -> Stream.run(stream) end, timeout: :infinity)
    end
  end

  defp collection_map do
    collections()
    |> Enum.map(&{&1.avr_id, &1.id})
    |> Enum.into(%{})
  end

  defp work_collections(ingest_sheet_id) do
    Rows.list_ingest_sheet_rows(sheet_id: ingest_sheet_id)
    |> Enum.map(fn row ->
      row
      |> Row.field_value(:label)
      |> String.split(~r([/.]))
      |> Enum.take(2)
      |> Enum.reverse()
      |> List.to_tuple()
    end)
    |> Enum.into(%{})
  end

  defp collections(binary_ids \\ true) do
    result =
      Meadow.Config.priv_path("avr_migration/avr_collections.json")
      |> File.read!()
      |> Jason.decode!(keys: :atoms)

    if binary_ids do
      result
      |> Enum.map(fn attrs ->
        Map.update!(attrs, :id, &Ecto.UUID.dump!/1)
      end)
    else
      result
    end
  end
end
