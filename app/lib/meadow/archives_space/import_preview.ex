defmodule Meadow.ArchivesSpace.ImportPreview do
  @moduledoc """
  Generates an on-demand AI metadata preview for an ArchivesSpace import.

  The ingest-sheet counterpart, `Meadow.Ingest.AIPreview`, samples up to 3
  IMAGE works from a persisted sheet. This module does the same for an
  ArchivesSpace resource *before* anything is imported: it walks the
  resource, takes the first few archival objects at the importable levels
  that carry digital-object images, pulls those images into the ingest
  bucket (via `Meadow.ArchivesSpace.Digital`, exactly as a real import
  would), and sends them to the metadata agent. The agent calls
  `get_ingest_image` and `authority_search` for each, then submits the
  structured results through the `submit_archives_space_previews` MCP tool,
  which writes them to `Meadow.ArchivesSpace.PreviewStore` keyed by a
  one-off token this module reads back.

  No works or file sets are created — this only previews what an AI-enabled
  import would produce, so a reviewer can approve before committing.
  """

  require Logger

  alias Meadow.ArchivesSpace.{Client, Digital, Importer, PreviewStore}
  alias Meadow.Notification

  @default_levels ~w(file item)
  @sample_size 3
  @estimate_fudge_factor 1.3
  @preview_accession_prefix "aspace-preview:"

  @system_prompt """
  You are a digital library metadata specialist generating structured previews for ingest review.
  Use the available tools to gather information about each work, then call submit_archives_space_previews
  to store the results. Do not return the results as text.
  """

  @prompt_header """
  Generate metadata previews for the following IMAGE works from an ArchivesSpace finding aid.

  For EACH work listed below:
  1. Call `get_ingest_image` with the S3 URI to view the image.
  2. Call `authority_search`  to find 3 appropriate subject headings
    based on what you see — people, places, events, topics, or objects in the image.
    Use authority_code: "lcnaf" for names and "fast" for everything else.
  3. Write a concise descriptive summary (1-3 sentences).

  Works to preview:
  """

  @doc """
  Starts background preview generation and returns a token immediately.

  The agent can run far longer than an HTTP request survives, so generation
  runs in a supervised task and the finished preview (or an error) is
  published to the `archives_space_import_preview` subscription keyed by the
  returned token. Built for the GraphQL start mutation.
  """
  def start(resource_uri, opts \\ []) do
    token = Ecto.UUID.generate()

    Task.Supervisor.start_child(Meadow.ArchivesSpace.TaskSupervisor, fn ->
      resource_uri
      |> generate(Keyword.put(opts, :token, token))
      |> publish_result(token)
    end)

    token
  end

  @doc "The subscription topic a preview's result is published to."
  def topic(token), do: "archives_space_import_preview:#{token}"

  defp publish_result({:ok, summary}, token) do
    publish(Map.merge(summary, %{token: token, status: :complete}), token)
  end

  defp publish_result({:error, reason}, token) do
    Logger.warning("ImportPreview: generation failed for #{token}: #{inspect(reason)}")

    publish(
      %{
        token: token,
        status: :error,
        previews: [],
        estimated_cost: nil,
        sample_count: 0,
        total_count: 0,
        error: error_message(reason)
      },
      token
    )
  end

  defp publish(payload, token) do
    Notification.publish(payload, archives_space_import_preview: topic(token))
  end

  defp error_message(reason) when is_binary(reason), do: reason
  defp error_message(reason), do: inspect(reason)

  @doc """
  Builds a preview for up to #{@sample_size} sample works in a resource.

  Returns `{:ok, summary}` where summary has:

    * `:previews` - list of preview maps (`:work_accession_number`,
      `:title`, `:description`, `:subjects`, `:thumbnail`)
    * `:estimated_cost` - rough total cost (USD) of running AI metadata over
      the whole resource, extrapolated from the sample
    * `:sample_count` - number of works actually previewed
    * `:total_count` - number of archival objects in the resource (an upper
      bound on the works an import would create)

  ## Options

    * `:levels` - archival object levels to sample (default: `#{inspect(@default_levels)}`)
  """
  def generate(resource_uri, opts \\ []) do
    token = Keyword.get(opts, :token) || Ecto.UUID.generate()
    levels = Keyword.get(opts, :levels, @default_levels)

    with {:ok, uris} <- Importer.archival_object_uris(resource_uri) do
      case sample_works(uris, levels) do
        [] ->
          {:ok, %{previews: [], estimated_cost: 0.0, sample_count: 0, total_count: length(uris)}}

        samples ->
          {:ok, run_preview(samples, length(uris), token)}
      end
    end
  end

  # Walks the resource in tree order, keeping the first @sample_size archival
  # objects at an importable level that carry at least one digital-object image.
  defp sample_works(uris, levels) do
    Enum.reduce_while(uris, [], fn uri, acc ->
      case sample_for(uri, levels) do
        nil -> {:cont, acc}
        sample -> accumulate_sample(acc, sample)
      end
    end)
  end

  defp accumulate_sample(acc, sample) do
    acc = acc ++ [sample]
    if length(acc) >= @sample_size, do: {:halt, acc}, else: {:cont, acc}
  end

  defp sample_for(uri, levels) do
    with {:ok, archival_object} <- Client.get_record(uri),
         true <- Map.get(archival_object, "level") in levels do
      accession = @preview_accession_prefix <> accession_id(archival_object)

      case Digital.ingest_file_sets(archival_object, accession) do
        {[%{core_metadata: %{location: s3_uri}} | _], _representative} ->
          %{accession: accession, archival_object: archival_object, s3_uri: s3_uri}

        _ ->
          nil
      end
    else
      _ -> nil
    end
  end

  defp run_preview(samples, total_count, token) do
    PreviewStore.open(token)

    try do
      cost = invoke_agent(samples, token)
      previews = PreviewStore.get(token) || []

      %{
        previews: merge_titles(previews, samples),
        estimated_cost: estimate_cost(cost, length(samples), total_count),
        sample_count: length(samples),
        total_count: total_count
      }
    after
      PreviewStore.close(token)
    end
  end

  # The metadata agent runs out-of-process and writes its results back to
  # PreviewStore via the MCP tool, so this only needs the cost out of the
  # response. Overridable via application env so tests can populate the store
  # and report a cost without invoking the real agent.
  defp invoke_agent(samples, token) do
    result =
      case Application.get_env(:meadow, :archives_space_preview_agent) do
        nil -> default_invoke_agent(samples, token)
        fun when is_function(fun, 2) -> fun.(samples, token)
      end

    case result do
      {:ok, cost} when is_number(cost) ->
        cost

      {:ok, _} ->
        0.0

      {:error, reason} ->
        Logger.warning("ImportPreview: agent call failed: #{inspect(reason)}")
        0.0
    end
  end

  defp default_invoke_agent(samples, token) do
    prompt = build_prompt(samples, token)

    case MeadowAI.query(prompt, context: %{system_prompt: String.trim(@system_prompt)}) do
      {:ok, response} -> {:ok, Map.get(response, "total_cost_usd", 0.0)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_prompt(samples, token) do
    work_lines =
      samples
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {%{accession: accession, s3_uri: s3_uri}, idx} ->
        "#{idx}. Work accession: #{accession} | Image: #{s3_uri}"
      end)

    @prompt_header <>
      work_lines <>
      """


      When you have finished analyzing all works, call `submit_archives_space_previews` with:
        - token: "#{token}"
        - previews: an array with one entry per work, each containing:
            - work_accession_number
            - filename (the S3 URI from the work listing above)
            - description
            - subjects (array of {id, label} from authority_search)
      """
  end

  # Attaches each sample's archival-object title to its returned preview so the
  # review UI can show it alongside the AI-generated description.
  defp merge_titles(previews, samples) do
    titles =
      Map.new(samples, fn %{accession: accession, archival_object: archival_object} ->
        {accession, archival_object["display_string"] || archival_object["title"]}
      end)

    Enum.map(previews, fn preview ->
      Map.put(preview, :title, Map.get(titles, preview.work_accession_number))
    end)
  end

  defp estimate_cost(_cost, 0, _total_count), do: 0.0

  defp estimate_cost(cost, sample_count, total_count) do
    Float.round(cost / sample_count * total_count * @estimate_fudge_factor, 2)
  end

  defp accession_id(%{"ref_id" => ref_id}) when is_binary(ref_id), do: ref_id
  defp accession_id(%{"uri" => uri}), do: uri |> String.split("/") |> List.last()
end
