defmodule Mix.Tasks.Meadow.DcDownload do
  @shortdoc "Export images and data from NUL Digital Collections to a Meadow ingest sheet"

  @moduledoc """
  A Mix task to export images and data from NUL Digital Collections to a
  Meadow ingest sheet.

      mix meadow.dc_download export_name query [max_results]

  Parameters:
  - `export_name`: the name of this export task, which will be used to create
     the spreadsheet and images. The above example will create a spreadsheet
     at `priv/seed_data/export_name.csv` and download all referenced images into
     `priv/seed_data/export_name/`.
  - `query`:
    - a valid DC collection ID (e.g. `faf4f60e-78e0-4fbf-96ce-4ca8b4df597a` for the World War II Poster Collection)
    - a valid Elasticsearch query fragment (e.g., `{"based_near.label.keyword": "England--London"}`)
  - `max_results` (optional): The maximum number of works to export
  """

  use Mix.Task

  alias NimbleCSV.RFC4180, as: CSV
  require Logger

  @dcapi_url "https://dcapi.stack.rdc.library.northwestern.edu/search"
  @iiif_url "https://iiif.stack.rdc.library.northwestern.edu/iiif/2"

  def run([output_path, query]), do: run([output_path, query, nil])

  def run([output_path, query, max_results]),
    do: export(Path.join("priv/seed_data", output_path), query, max_results)

  defp export(export_name, query, max_results) do
    Application.ensure_all_started(:hackney)

    base_path = export_name |> Path.split() |> Enum.drop(-1) |> Path.join()

    with data <- gather_data(export_name, query, max_results) do
      rows =
        data
        |> Enum.with_index(1)
        |> Enum.map(fn {{{fsid, filename}, row}, index} ->
          filename = Path.join(export_name, filename)

          Logger.info("Downloading image #{index}/#{length(data)}...")

          case HTTPoison.get!("#{@iiif_url}/#{fsid}/full/!2048,2048/0/default.jpg") do
            %{status_code: 200, body: body} -> File.write!(filename, body)
            %{body: other} -> fatal_error("Error retrieving image #{fsid}: #{other}")
            other -> fatal_error("Error retrieving image #{fsid}: #{other}")
          end

          row |> List.replace_at(2, Path.relative_to(filename, base_path))
        end)

      with csv_path <- export_name <> ".csv" do
        Logger.info("Writing ingest sheet to #{csv_path}")

        [
          [
            "work_accession_number",
            "accession_number",
            "filename",
            "description",
            "role",
            "label"
          ]
          | rows
        ]
        |> CSV.dump_to_stream()
        |> Stream.into(File.stream!(csv_path, [:write, :utf8]))
        |> Stream.run()
      end

      Logger.info("Export complete.")
    end
  end

  defp fatal_error(error) do
    Logger.error(error)
    Kernel.exit(:error)
  end

  defp gather_data(output_path, query, max_results) do
    File.mkdir_p!(output_path)

    Logger.info("Fetching search results...")

    fetch_collection_data(query, max_results)
    |> get_in(["hits", "hits"])
    |> process_search_results()
  end

  defp process_search_results([]) do
    Logger.warn("No results found for query. Exiting.")
    exit(:normal)
  end

  defp process_search_results(hits) do
    Logger.info("Processing #{length(hits)} results...")
    Enum.flat_map(hits, &fetch_image_info/1)
  end

  defp fetch_image_info(%{
         "_source" => %{"accession_number" => work_accession_number, "member_ids" => file_set_ids}
       }) do
    file_set_ids
    |> Enum.with_index()
    |> Enum.map(fn {fsid, index} ->
      response = HTTPoison.get!("#{@dcapi_url}/common/_doc/#{fsid}")

      case response do
        %{status_code: 200, body: body} ->
          %{"_source" => doc} = Jason.decode!(body)
          filename = doc |> Map.get("label") |> String.replace(".tif", ".jpg")

          {{fsid, filename},
           [
             work_accession_number,
             "#{work_accession_number}_FILE_#{index}",
             filename,
             doc["label"],
             Enum.random(["A", "A", "A", "A", "P"]),
             "#{filename} Label"
           ]}

        %{status_code: 403} ->
          nil

        %{body: other} ->
          fatal_error("Error retrieving info for file set #{fsid}: #{other}")

        other ->
          fatal_error("Error retrieving info for file set #{fsid}: #{other}")
      end
    end)
  end

  defp fetch_collection_data(query, max_results) do
    query_stanza =
      case Jason.decode(query) do
        {:ok, q} -> q
        {:error, _} -> %{"collection.id" => query}
      end

    body =
      %{
        query: %{
          bool: %{
            must: [
              %{match: query_stanza},
              %{match: %{"model.name" => "Image"}},
              %{match: %{visibility: "open"}}
            ]
          }
        },
        _source: ["accession_number", "member_ids"],
        size: max_results
      }
      |> Jason.encode!()

    response =
      HTTPoison.post!("#{@dcapi_url}/common/_search", body, [{"Content-Type", "application/json"}])

    case response do
      %{status_code: 200, body: body} -> Jason.decode!(body)
      %{body: other} -> fatal_error("Error retrieving search results: #{other}")
      other -> fatal_error("Error retrieving search results: #{other}")
    end
  end
end
