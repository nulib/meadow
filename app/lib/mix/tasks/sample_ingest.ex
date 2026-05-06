defmodule Mix.Tasks.Meadow.SampleIngest do
  @moduledoc """
  Create a project (or reuse an existing one), upload sample fixture media and
  a generated CSV to S3, then run a sample ingest end-to-end against the
  current Meadow environment's real S3 / RDS.

  ## Command line options

    * `--title`       - Sheet title prefix (default: `"Sample Ingest <unix-ts>"`)
    * `--project`     - Existing project title to ingest into. If a project with
                        that title exists it is reused; otherwise a new project
                        is created with that title. If omitted, a new project is
                        created using `--title`.
    * `--fixture-dir` - Directory to read source media from
                        (default: `"test/fixtures"`)
    * `--ai`          - Create the sheet as an AI ingest (`ai_ingest: true`)
    * `--mode`        - One of:
                          * `validate` — stop after validation (status: valid)
                          * `preview`  — AI only: kick off `AIPreview` and stop
                                         at `awaiting_approval`
                          * `ingest`   — auto-approve and create works (default)
    * `--keep-pending` - Alias for `--mode validate`

  ## Examples

      mix meadow.sample_ingest
      mix meadow.sample_ingest --title "Smoke 1234"
      mix meadow.sample_ingest --project "QA Sandbox"
      mix meadow.sample_ingest --mode validate
      mix meadow.sample_ingest --ai --mode preview
      mix meadow.sample_ingest --ai --mode ingest
  """

  use Mix.Task

  alias Meadow.Config
  alias Meadow.Ingest.{AIPreview, Projects, Sheets, SheetsToWorks, Validator}
  alias Meadow.Utils.AWS
  alias NimbleCSV.RFC4180, as: CSV

  require Logger

  @shortdoc "Run an end-to-end sample ingest in the current Meadow environment"

  @opts [
    title: :string,
    project: :string,
    fixture_dir: :string,
    ai: :boolean,
    mode: :string,
    keep_pending: :boolean
  ]

  @headers ~w(work_type work_accession_number file_accession_number filename description role label work_image structure)

  # Each row: {work_type, work_key, file_key, filename, description, role, label, work_image, structure}
  # work_key/file_key are placeholders that get expanded into per-run UUIDs.
  @rows [
    {"IMAGE", :w1, :f1_1, "coffee.tif", "Letter, page 1, Dear Sir, recto", "A", "The label", "",
     ""},
    {"IMAGE", :w1, :f1_2, "coffee.tif", "Letter, page 1, Dear Sir, verso, blank", "P",
     "The label", "", ""},
    {"IMAGE", :w1, :f1_3, "coffee.tif", "Letter, page 2, If these papers, recto", "A",
     "The label", "TRUE", ""},
    {"IMAGE", :w1, :f1_4, "coffee.tif", "Letter, page 2, If these papers, verso, blank", "X",
     "The label", "", ""},
    {"VIDEO", :w2, :f2_1, "small.m4v", "Photo, man with two children", "A", "The label", "",
     "Donohue_002_01.vtt"},
    {"VIDEO", :w2, :f2_2, "small.m4v", "Small Video", "A", "The label", "", ""},
    {"VIDEO", :w2, :f2_3, "coffee.tif", "Photo, two children praying", "X", "The label", "", ""},
    {"VIDEO", :w2, :f2_4, "details.json", "Supplemental information", "S", "Supplement", "", ""}
  ]

  @source_files ~w(coffee.tif small.m4v details.json Donohue_002_01.vtt)

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @opts)
    opts = normalize_opts(opts)

    # AI ingests need both the MeadowAI.MetadataAgent and the MCP endpoint it
    # gives to the metadata-agent lambda.
    System.put_env("MEADOW_PROCESSES", if(opts.ai, do: "web.server,agent", else: "none"))
    Mix.Task.run("app.start")
    Logger.configure(level: :info)

    project = resolve_project(opts)
    Logger.info("Project: #{project.title} (#{project.id}) folder=#{project.folder}")

    upload_source_files(project, opts.fixture_dir)

    {csv_key, sheet_title} = upload_csv(project, opts.title)

    sheet = create_sheet(project, sheet_title, csv_key, opts.ai)
    Logger.info("Sheet created: #{sheet.title} (#{sheet.id}) ai_ingest=#{sheet.ai_ingest}")

    case Validator.result(sheet.id) do
      "pass" ->
        Logger.info("Validation: pass")
        run_mode(opts.mode, sheet)

      other ->
        Logger.error("Validation: #{other}")

        sheet.id
        |> Sheets.ingest_errors()
        |> Enum.each(fn error -> Logger.error(inspect(error)) end)

        exit({:shutdown, 1})
    end
  rescue
    exception ->
      Logger.error(Exception.message(exception))
      reraise exception, __STACKTRACE__
  end

  defp normalize_opts(opts) do
    title =
      Keyword.get(opts, :title) ||
        "Sample Ingest #{DateTime.utc_now() |> DateTime.to_unix()}"

    mode =
      cond do
        Keyword.get(opts, :keep_pending) -> "validate"
        m = Keyword.get(opts, :mode) -> m
        true -> "ingest"
      end

    unless mode in ~w(validate preview ingest) do
      raise ArgumentError,
            "--mode must be one of validate, preview, ingest (got #{inspect(mode)})"
    end

    ai = Keyword.get(opts, :ai, false)

    if mode == "preview" and not ai do
      raise ArgumentError, "--mode preview requires --ai"
    end

    %{
      title: title,
      project: Keyword.get(opts, :project),
      fixture_dir: Keyword.get(opts, :fixture_dir, "test/fixtures"),
      ai: ai,
      mode: mode
    }
  end

  defp resolve_project(%{project: nil, title: title}) do
    {:ok, project} = Projects.create_project(%{title: title})
    project
  end

  defp resolve_project(%{project: name}) do
    case Projects.get_project_by_title(name) do
      nil ->
        {:ok, project} = Projects.create_project(%{title: name})
        project

      project ->
        project
    end
  end

  defp upload_source_files(project, fixture_dir) do
    bucket = Config.ingest_bucket()

    @source_files
    |> Enum.each(fn name ->
      path = Path.join(fixture_dir, name)
      key = "#{project.folder}/#{name}"

      ExAws.S3.put_object(bucket, key, File.read!(path))
      |> ExAws.request!()

      Logger.info("Uploaded s3://#{bucket}/#{key}")

      wait_for_tags(bucket, key)
    end)
  end

  defp upload_csv(project, title) do
    short = short_id()
    accession_keys = @rows |> Enum.flat_map(fn {_, w, f, _, _, _, _, _, _} -> [w, f] end) |> Enum.uniq()
    accession_map = Map.new(accession_keys, fn key -> {key, Ecto.UUID.generate()} end)

    csv_rows =
      Enum.map(@rows, fn {wt, w, f, filename, desc, role, label, image, structure} ->
        [
          wt,
          Map.fetch!(accession_map, w),
          Map.fetch!(accession_map, f),
          filename,
          desc,
          role,
          label,
          image,
          structure
        ]
      end)

    csv_body =
      [@headers | csv_rows]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()

    sheet_title = "#{title} (#{short})"
    bucket = Config.upload_bucket()
    key = "sample_ingest/#{short}.csv"

    ExAws.S3.put_object(bucket, key, csv_body)
    |> ExAws.request!()

    Logger.info("Uploaded s3://#{bucket}/#{key}")

    _ = project
    {key, sheet_title}
  end

  defp short_id do
    Ecto.UUID.generate() |> String.split("-") |> List.first()
  end

  defp wait_for_tags(bucket, key) do
    required = Config.required_checksum_tags()
    timeout = Config.checksum_wait_timeout()
    deadline = System.monotonic_time(:millisecond) + timeout

    do_wait_for_tags(bucket, key, required, deadline)
  end

  defp do_wait_for_tags(bucket, key, required, deadline) do
    cond do
      AWS.check_object_tags!(bucket, key, required) ->
        :ok

      System.monotonic_time(:millisecond) >= deadline ->
        raise "Timed out waiting for tags #{inspect(required)} on s3://#{bucket}/#{key}"

      true ->
        :timer.sleep(500)
        do_wait_for_tags(bucket, key, required, deadline)
    end
  end

  defp create_sheet(project, title, csv_key, ai) do
    filename = "s3://#{Config.upload_bucket()}/#{csv_key}"

    {:ok, sheet} =
      Sheets.create_ingest_sheet(%{
        title: title,
        project_id: project.id,
        filename: filename,
        ai_ingest: ai
      })

    sheet
  end

  defp run_mode("validate", sheet) do
    sheet = Sheets.get_ingest_sheet!(sheet.id)
    Logger.info("Stopping at status=#{sheet.status} (mode=validate)")
  end

  defp run_mode("preview", sheet) do
    {:ok, sheet} = Sheets.update_ingest_sheet_status(sheet, "generating_preview")
    generate_ai_preview(sheet)

    sheet = Sheets.get_ingest_sheet!(sheet.id)
    Logger.info("Stopping at status=#{sheet.status} (mode=preview)")
  end

  defp run_mode("ingest", %{ai_ingest: true} = sheet) do
    {:ok, sheet} = Sheets.update_ingest_sheet_status(sheet, "generating_preview")
    generate_ai_preview(sheet)

    sheet.id
    |> Sheets.get_ingest_sheet!()
    |> approve_and_create_works()
  end

  defp run_mode("ingest", sheet) do
    approve_and_create_works(sheet)
  end

  defp generate_ai_preview(sheet) do
    Logger.info(
      "Invoking metadata-agent lambda"
    )

    parent = self()
    started_at = System.monotonic_time(:second)

    task =
      Task.async(fn ->
        result = AIPreview.generate_and_store(sheet)
        send(parent, :ai_preview_done)
        result
      end)

    heartbeat(started_at)
    Task.await(task, :infinity)
  end

  defp heartbeat(started_at) do
    receive do
      :ai_preview_done -> :ok
    after
      30_000 ->
        elapsed = System.monotonic_time(:second) - started_at
        Logger.info("...still generating AI preview (#{elapsed}s elapsed)")
        heartbeat(started_at)
    end
  end

  defp approve_and_create_works(sheet) do
    {:ok, sheet} = Sheets.update_ingest_sheet_status(sheet, "approved")

    sheet = SheetsToWorks.create_works_from_ingest_sheet(sheet, :sync)

    works =
      sheet
      |> Meadow.Repo.preload(:works)
      |> Map.get(:works)

    Logger.info("Created #{length(works)} work(s):")

    Enum.each(works, fn work ->
      Logger.info("  - #{work.id} (accession=#{work.accession_number})")
    end)

    Logger.info("Final status=#{Sheets.get_ingest_sheet!(sheet.id).status}")
  end
end
