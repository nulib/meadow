defmodule AVR.Migration.FileSets do
  alias Meadow.Data.FileSets
  alias Meadow.Repo

  import AVR.Migration
  import SweetXml, only: [sigil_x: 2]

  def import_filesets(bucket, prefix) do
    ExAws.S3.list_objects_v2(bucket, prefix: prefix)
    |> ExAws.stream!()
    |> Stream.each(fn %{key: key} ->
      ExAws.S3.get_object(bucket, key)
      |> ExAws.request!()
      |> Map.get(:body)
      |> Jason.decode!(keys: :atoms)
      |> import_work_filesets()
    end)
    |> Stream.run()
  end

  defp import_work_filesets([]), do: :noop

  defp import_work_filesets(master_files) do
    with %{mediaobject_id: mediaobject_id} <- List.first(master_files) do
      case find_avr_work(mediaobject_id) do
        nil ->
          :noop

        work ->
          Repo.transaction(fn ->
            master_files
            |> Enum.each(&create_fileset(work, &1))
          end)
      end
    end
  end

  defp create_fileset(work, masterfile_attrs) do
    case masterfile_attributes(work, masterfile_attrs) |> FileSets.create_file_set() do
      {:ok, file_set} -> {:ok, file_set}
      {:error, error} -> raise error
    end
  end

  def masterfile_attributes(work, masterfile_attrs) do
    with original_filename <- Path.basename(masterfile_attrs.location) do
      %{
        accession_number: "avr:#{masterfile_attrs.masterfile_id}",
        role: %{id: "A", scheme: "file_set_role"},
        work_id: work.id,
        poster_offset: masterfile_attrs.poster_offset,
        core_metadata: %{
          location: masterfile_attrs.location,
          original_filename: original_filename,
          label: masterfile_attrs |> get_label(original_filename)
        },
        structural_metadata: convert_structural_metadata(masterfile_attrs.structural_metadata)
      }
    end
  end

  defp get_label(%{label: value}, _) when is_binary(value) and byte_size(value) > 0, do: value
  defp get_label(_, default), do: default

  def convert_structural_metadata(nil), do: nil

  def convert_structural_metadata(xml) do
    with doc <- SweetXml.parse(xml),
         spans <-
           SweetXml.xpath(doc, ~x"//Span"l,
             label: ~x"./@label"s,
             begin: ~x"./@begin"s,
             end: ~x"./@end"s
           )
           |> to_vtt() do
      ["WEBVTT\n" | ["\n" | spans]]
      |> IO.iodata_to_binary()
      |> String.trim()
      |> then(&%{type: "webvtt", value: &1})
    end
  end

  defp to_vtt(spans) do
    spans
    |> Enum.map(fn %{label: label, begin: start_time, end: end_time} ->
      [to_vtt_time(start_time), " --> ", to_vtt_time(end_time), "\n", label, "\n", "\n"]
    end)
  end

  defp to_vtt_time(time) do
    with parts <- String.split(time, ":") do
      parts
      |> Enum.reverse()
      |> Enum.take(3)
      |> Enum.reverse()
      |> Enum.map(fn part ->
        part |> String.pad_leading(2, "0")
      end)
      |> Enum.join(":")
    end <> ".000"
  end
end
