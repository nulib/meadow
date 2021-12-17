defmodule AVR.Migration do
  @moduledoc """
  Support code for AVR -> Meadow migration
  """

  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Ingest.Rows
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.Repo
  alias NUL.Schemas.AuthorityRecord
  alias NUL.AuthorityRecords

  import Ecto.{Changeset, Query}

  def import_collections do
    collections()
    |> Enum.map(fn collection_attributes ->
      case Repo.get(Collection, collection_attributes.id) do
        nil -> Collections.create_collection(collection_attributes)
        collection -> {:ok, collection}
      end
    end)
  end

  def import_subjects(write_back \\ false) do
    with subjects <- subjects() |> Enum.map(&find_or_create_subject/1) do
      if write_back, do: save_json(subjects, "avr_subjects.json")
    end
  end

  def find_avr_work(mediaobject_id) do
    from(w in Work, where: w.accession_number == ^"avr:#{mediaobject_id}") |> Repo.one()
  end

  def list_avr_works do
    from(w in Work, where: like(w.accession_number, "avr:%"), preload: :file_sets)
    |> Repo.all()
  end

  def find_avr_fileset(masterfile_id) do
    from(fs in FileSet, where: fs.accession_number == ^"avr:#{masterfile_id}") |> Repo.one()
  end

  def list_avr_filesets do
    from(fs in FileSet,
      where: like(fs.accession_number, "avr:%"),
      where: not like(fs.accession_number, "%:mods")
    )
    |> Repo.all()
  end

  defp find_or_create_subject(%{id: id} = attributes) do
    case AuthorityRecords.get_authority_record(id) do
      nil ->
        with {:ok, result} <-
               %AuthorityRecord{}
               |> AuthorityRecord.changeset(attributes)
               |> put_change(:id, id)
               |> Repo.insert() do
          result
        end

      record ->
        record
    end
  end

  defp find_or_create_subject(attributes) do
    case from(r in AuthorityRecord, where: r.label == ^attributes.label) |> Repo.all() do
      [record | _] ->
        record

      [] ->
        with {:ok, result} <- AuthorityRecords.create_authority_record(attributes) do
          result
        end
    end
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

  def collections(binary_ids \\ true), do: load_json("avr_collections.json", binary_ids)
  def subjects, do: load_json("avr_subjects.json", false)

  defp load_json(file, binary_ids) do
    result =
      Meadow.Config.priv_path("avr_migration/#{file}")
      |> File.read!()
      |> Jason.decode!(keys: :atoms)

    if binary_ids do
      result
      |> Enum.map(fn
        %{id: _} = attrs -> Map.update!(attrs, :id, &Ecto.UUID.dump!/1)
        attrs -> attrs
      end)
    else
      result
    end
  end

  defp save_json(content, file) do
    content =
      content
      |> Enum.map(fn record ->
        record
        |> Map.from_struct()
        |> Enum.reject(fn {key, _} ->
          Enum.member?([:__meta__, :inserted_at, :updated_at], key)
        end)
        |> Enum.into(%{})
      end)
      |> Enum.map(fn
        %{id: id} = record ->
          case Ecto.UUID.cast(id) do
            {:ok, result} -> Map.put(record, :id, result)
            _ -> record
          end

        record ->
          record
      end)

    Meadow.Config.priv_path("avr_migration/#{file}")
    |> File.write!(Jason.encode!(content))
  end
end
