defmodule Meadow.Data.CSV.MetadataUpdateJobsTest do
  use Meadow.DataCase
  use Meadow.CSVMetadataUpdateCase
  use Meadow.IndexCase
  use Meadow.GeoNamesCase

  alias Ecto.Multi
  alias Meadow.AI.Provenance
  alias Meadow.AI.Provenance.Schemas.Target, as: ProvenanceTarget
  alias Meadow.Data.CSV.{BulkImport, Export, Import, MetadataUpdateJobs}
  alias Meadow.Data.{Indexer, Works}
  alias Meadow.Data.Schemas.{CSV.MetadataUpdateJob, ValueEntry, Work}
  alias Meadow.Repo
  alias Meadow.Search.Document
  alias Meadow.Utils.Stream, as: StreamUtil
  alias NimbleCSV.RFC4180, as: CSV

  import Meadow.Data.CSV.Utils, only: [combine_multivalued_field: 1, split_multivalued_field: 1]

  setup %{source_url: source_url} do
    with filename <- Path.basename(source_url) do
      {:ok,
       %{
         create_result:
           MetadataUpdateJobs.create_job(%{
             filename: filename,
             source: source_url,
             user: "validUser"
           })
       }}
    end
  end

  describe "missing file" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "create_job/1" do
      assert MetadataUpdateJobs.create_job(%{
               filename: "missing.csv",
               source: "s3://#{@upload_bucket}/missing.csv",
               user: "validUser"
             }) == {:error, "s3://#{@upload_bucket}/missing.csv does not exist"}
    end
  end

  describe "valid data" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    test "create_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert job.status == "pending"
      assert job.rows |> is_nil()
    end

    test "list_jobs/0", %{create_result: {:ok, job}} do
      assert MetadataUpdateJobs.list_jobs() == [job]
    end

    test "get_job/1", %{create_result: {:ok, job}} do
      assert MetadataUpdateJobs.get_job(job.id) == job
    end

    test "apply_job/1", %{create_result: {:ok, job}, works: works} do
      refute job.started_at
      assert {:ok, job} = MetadataUpdateJobs.apply_job(job)
      assert job.status == "complete"
      assert job.started_at

      assert MetadataUpdateJobs.apply_job(job) ==
               {:error, "Update Job cannot be applied: status is complete."}

      with original <- Enum.at(works, 31),
           work <- Works.get_work(original.id) |> Repo.preload(:metadata_update_jobs) do
        assert work.inserted_at == original.inserted_at
        assert work.published
        assert work.visibility.id == "AUTHENTICATED"

        assert work.descriptive_metadata.date_created == [
                 %{edtf: "~1899", humanized: "circa 1899"}
               ]

        assert work.administrative_metadata.project_proposer == [
                 "Socrates Poole",
                 "Lord Bowler"
               ]

        assert Enum.member?(work.metadata_update_jobs |> Enum.map(& &1.id), job.id)

        doc =
          work
          |> Repo.preload(Work.required_index_preloads())
          |> Document.encode(2)

        assert doc.csv_metadata_update_jobs == [job.id]
      end
    end

    test "next_job/0", %{create_result: {:ok, job}} do
      assert MetadataUpdateJobs.next_job() == job
      job |> MetadataUpdateJobs.update_job(%{active: true})
      assert MetadataUpdateJobs.next_job() |> is_nil()
    end

    test "reset_stalled/1" do
      with timestamp <- NaiveDateTime.utc_now() |> NaiveDateTime.add(-400, :second) do
        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0, 0}
        assert %{status: status, retries: retries} = MetadataUpdateJob |> Repo.one()
        assert status == "pending"
        assert retries == 0

        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "validating"])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0, 1}
        assert %{status: status, retries: retries} = MetadataUpdateJob |> Repo.one()
        assert status == "pending"
        assert retries == 1

        Repo.update_all(MetadataUpdateJob, set: [updated_at: timestamp, status: "processing"])
        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 0, 1}
        assert %{status: status, retries: retries} = MetadataUpdateJob |> Repo.one()
        assert status == "valid"
        assert retries == 2

        Repo.update_all(MetadataUpdateJob,
          set: [updated_at: timestamp, status: "validating", retries: 3]
        )

        assert MetadataUpdateJobs.reset_stalled(360) == {:ok, 1, 0}
        assert %{status: status, errors: errors} = MetadataUpdateJob |> Repo.one()
        assert status == "error"

        assert errors == [
                 %{"errors" => %{"status" => ["Stuck in validating after 3 retries"]}, "row" => 0}
               ]
      end
    end

    test "update_job/2", %{create_result: {:ok, job}} do
      [
        {"pending", false},
        {"valid", false},
        {"validating", true},
        {"processing", true},
        {"invalid", false}
      ]
      |> Enum.each(fn {status, active} ->
        with result <- MetadataUpdateJobs.update_job(job, %{status: status}) do
          assert result.active == active
        end
      end)
    end
  end

  describe "AI provenance" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    # Title the first CSV data row writes to the first fixture work
    @csv_title "Est qui ut quibusdam iure laudantium praesentium harum cumque repellendus!"

    defp seed_ai_target(work, field_path, proposed_value) do
      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          work_id: work.id,
          status: "completed"
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "Work",
            target_id: work.id,
            field_path: field_path,
            operation: "replace",
            proposed_value: proposed_value,
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      :ok
    end

    test "records human mediation when the CSV changes an AI-provenanced field",
         %{create_result: {:ok, job}, works: works} do
      work = Enum.at(works, 0)
      seed_ai_target(work, "descriptive_metadata.title", "Test title")

      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)

      entry =
        Provenance.work_summary(work.id)
        |> Enum.find(&(&1.field_path == "descriptive_metadata.title"))

      assert entry.origin == "ai_assisted_human_modified"
      assert entry.latest_event_type == "human_edited"

      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)
      event = Enum.find(target.events, &(&1.event_type == "human_edited"))

      assert event.actor == "validUser"
      assert event.value_before == %{"value" => "Test title"}
      assert event.value_after == %{"value" => @csv_title}
    end

    test "records a deletion when the CSV clears an AI-provenanced field",
         %{create_result: {:ok, job}, works: works} do
      {:ok, work} =
        works
        |> Enum.at(0)
        |> Works.update_work(%{descriptive_metadata: %{description: ["AI description"]}})

      seed_ai_target(work, "descriptive_metadata.description", ["AI description"])

      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)

      assert %{
               "descriptive_metadata.description" => %{
                 origin: "human_replacement_after_ai_suggestion",
                 status: "deleted",
                 latest_event_type: "deleted"
               }
             } = Provenance.target_summary_map("Work", work.id)
    end

    test "leaves fields without AI provenance untouched",
         %{create_result: {:ok, job}, works: works} do
      work = Enum.at(works, 0)
      seed_ai_target(work, "descriptive_metadata.title", "Test title")

      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)

      # The CSV also changes published, visibility, contributor, etc. on this
      # work, but only the AI-provenanced title may have a target.
      assert Provenance.target_summary_map("Work", work.id) |> Map.keys() ==
               ["descriptive_metadata.title"]
    end

    test "records nothing when no work has AI provenance", %{create_result: {:ok, job}} do
      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)
      assert Repo.aggregate(ProvenanceTarget, :count) == 0
    end

    test "snapshots only works with applied AI provenance",
         %{create_result: {:ok, job}, works: works} do
      work = Enum.at(works, 0)
      seed_ai_target(work, "descriptive_metadata.title", "Test title")

      stream =
        StreamUtil.stream_from(job.source)
        |> Import.read_csv()
        |> Import.stream()

      # import_stream must run inside the caller's transaction.
      {:ok, {:ok, before_works}} =
        Repo.transaction(fn -> BulkImport.import_stream(stream, job.id) end)

      assert [before_work] = before_works
      assert before_work.id == work.id
      assert before_work.descriptive_metadata.title == "Test title"
    end

    test "rolls back work updates when a later transaction step fails",
         %{create_result: {:ok, job}, works: works} do
      work = Enum.at(works, 0)
      original_title = work.descriptive_metadata.title

      stream =
        StreamUtil.stream_from(job.source)
        |> Import.read_csv()
        |> Import.stream()

      multi =
        Multi.new()
        |> Multi.run("import", fn repo, _ ->
          BulkImport.import_stream(stream, job.id, repo)
        end)
        |> Multi.run("provenance", fn _repo, _ -> {:error, :provenance_failed} end)

      assert {:error, "provenance", :provenance_failed, _} = Repo.transaction(multi)
      assert Repo.get!(Work, work.id).descriptive_metadata.title == original_title
    end

    test "record_ai_provenance converts recording failures into an error tuple",
         %{works: works} do
      work = Enum.at(works, 0)
      seed_ai_target(work, "descriptive_metadata.title", "Test title")

      # A tuple can't be JSON-encoded, so recording the human_edited event's
      # value_before raises inside the strict provenance path.
      bad_before = %{
        work
        | descriptive_metadata: %{work.descriptive_metadata | title: {:not, :encodable}}
      }

      assert {:error, %Protocol.UndefinedError{}} =
               BulkImport.record_ai_provenance([bad_before], "validUser")
    end

    test "does not record events when the CSV value matches the AI value",
         %{create_result: {:ok, job}, works: works} do
      {:ok, work} =
        works
        |> Enum.at(0)
        |> Works.update_work(%{descriptive_metadata: %{title: @csv_title}})

      seed_ai_target(work, "descriptive_metadata.title", @csv_title)

      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)

      assert %{"descriptive_metadata.title" => %{origin: "ai_generated"}} =
               Provenance.target_summary_map("Work", work.id)

      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)
      refute Enum.any?(target.events, &(&1.event_type == "human_edited"))
    end
  end

  describe "item identity across metadata updates" do
    @describetag source: "test/fixtures/csv/sheets/valid.csv"

    # Provenance attaches to each item's stable id, so a CSV metadata update
    # must never remint the id of an item it did not change.

    test "re-applying identical metadata is a no-op for item identity", %{
      create_result: {:ok, job},
      works: works,
      source_url: source_url
    } do
      assert {:ok, _job} = MetadataUpdateJobs.apply_job(job)

      work = works |> Enum.at(31) |> Map.get(:id) |> Works.get_work()
      original = item_ids(work)

      # Same file, second job: every cell re-sends the same id-less values
      # (free text, notes, related URLs). Each item's content is unchanged, so
      # each keeps its id by exact-match rehydration.
      {:ok, second_job} =
        MetadataUpdateJobs.create_job(%{
          filename: Path.basename(source_url),
          source: source_url,
          user: "validUser"
        })

      assert {:ok, _job} = MetadataUpdateJobs.apply_job(second_job)

      reapplied = Works.get_work(work.id)
      assert item_ids(reapplied) == original

      assert ValueEntry.values(reapplied.descriptive_metadata.description) ==
               ValueEntry.values(work.descriptive_metadata.description)
    end

    test "an exported, edited, and re-imported value keeps its id", %{
      create_result: {:ok, job},
      works: works
    } do
      assert {:ok, _job} = MetadataUpdateJobs.apply_job(job)

      work = works |> Enum.at(31) |> Map.get(:id) |> Works.get_work()
      [first_entry | rest] = work.descriptive_metadata.description
      Indexer.synchronize_index()

      # Export the work, edit the first description in place (its exported
      # `id:value` prefix intact), and apply the result as a new update job.
      edited_value = first_entry.value <> " (edited)"

      content =
        %{query: %{ids: %{values: [work.id]}}}
        |> Export.generate_csv()
        |> replace_cell("description", fn cell ->
          [_first | others] = split_multivalued_field(cell)

          ["#{first_entry.id}:#{edited_value}" | others]
          |> combine_multivalued_field()
        end)

      assert {:ok, edit_job} = create_job_with_content(content, "roundtrip.csv")
      assert {:ok, _job} = MetadataUpdateJobs.apply_job(edit_job)

      [edited | unchanged] = Works.get_work(work.id).descriptive_metadata.description

      # The edited item kept its identity with its new value; the untouched
      # items kept theirs exactly.
      assert edited.id == first_entry.id
      assert edited.value == edited_value
      assert Enum.map(unchanged, &{&1.id, &1.value}) == Enum.map(rest, &{&1.id, &1.value})
    end

    test "rejects a CSV item id copied from another work", %{
      create_result: {:ok, job},
      works: works
    } do
      assert {:ok, _job} = MetadataUpdateJobs.apply_job(job)

      work = works |> Enum.at(31) |> Map.get(:id) |> Works.get_work()
      [entry | _] = work.descriptive_metadata.description

      foreign_work =
        work_fixture(%{
          descriptive_metadata: %{title: "Foreign identity source", description: ["Foreign"]}
        })

      [foreign_entry] = foreign_work.descriptive_metadata.description
      Indexer.synchronize_index()

      content =
        %{query: %{ids: %{values: [work.id]}}}
        |> Export.generate_csv()
        |> replace_cell("description", fn cell ->
          [_first | others] = split_multivalued_field(cell)

          ["#{foreign_entry.id}:#{entry.value}" | others]
          |> combine_multivalued_field()
        end)

      assert {:ok, copied_id_job} = create_job_with_content(content, "copied-id.csv")

      assert {:error, "validation", %{errors: errors}} =
               MetadataUpdateJobs.apply_job(copied_id_job)

      assert inspect(errors) =~ "does not belong to this field"
      assert hd(Works.get_work!(work.id).descriptive_metadata.description).id == entry.id
    end
  end

  describe "bad headers" do
    @describetag source: "test/fixtures/csv/sheets/bad_headers.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)

      assert errors == [
               %{errors: %{published: ["is missing"], publishedd: ["is unknown"]}, row: 1}
             ]
    end
  end

  describe "missing headers" do
    @describetag source: "test/fixtures/csv/sheets/missing_headers.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)

      assert errors == [
               %{errors: %{headers: ["could not identify header row"]}, row: 1}
             ]
    end
  end

  describe "query row flexibility" do
    @tag source: "test/fixtures/csv/sheets/extra_query_rows.csv"

    test "apply_job/1 with extra query rows", %{create_result: {:ok, job}} do
      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)
    end

    @tag source: "test/fixtures/csv/sheets/missing_query_row.csv"
    test "apply_job/1 with no query row", %{create_result: {:ok, job}} do
      assert {:ok, %{status: "complete"}} = MetadataUpdateJobs.apply_job(job)
    end
  end

  describe "coded term validation" do
    @describetag source: "test/fixtures/csv/sheets/invalid_coded_term.csv"
    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "subject#1" => [
                     ~s'"METAPHORICAL" is an invalid coded term for scheme SUBJECT_ROLE'
                   ]
                 },
                 row: 15
               }
             ]
    end
  end

  describe "controlled terms preflight failure" do
    @describetag source: "test/fixtures/csv/sheets/invalid_terms.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "http://id.loc.gov/authorities/subjects/sh85070610 TOPICAL:http://id.loc.gov/authorities/subjects/sh85076671" =>
                     "is from an unknown authority",
                   "http://id.loc.gov/authorities/names/blahblah" =>
                     "is from an unknown authority",
                   "http://id.lock.gov/authorities/names/n79091588" =>
                     "is from an unknown authority"
                 },
                 row: 0
               }
             ]
    end
  end

  describe "bad subjects" do
    @describetag source: "test/fixtures/csv/sheets/bad_subjects.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{
                 errors: %{
                   "GEOGRAPHICAL:bad subject" => "is from an unknown authority",
                   "unqualified bad subject" => "is from an unknown authority"
                 },
                 row: 0
               }
             ]
    end
  end

  describe "invalid data" do
    @describetag source: "test/fixtures/csv/sheets/invalid.csv"

    test "apply_job/1", %{create_result: result} do
      assert {:ok, job} = result
      assert {:error, "validation", %{errors: errors}} = MetadataUpdateJobs.apply_job(job)
      refute MetadataUpdateJobs.get_job(job.id) |> Map.get(:active)

      assert errors == [
               %{errors: %{"notes" => ["cannot have a blank id"]}, row: 10},
               %{
                 errors: %{
                   "contributor#3" => [~s'"nop" is an invalid coded term for scheme MARC_RELATOR']
                 },
                 row: 12
               },
               %{errors: %{"id" => ~s'"NOT_A_UUID" is not a valid UUID'}, row: 13},
               %{
                 errors: %{
                   "date_created" => ~s'[%{edtf: "bad_date"}, %{edtf: "201?"}] is invalid'
                 },
                 row: 14
               },
               %{
                 errors: %{"id" => ~s'"0bde5432-0b7b-4f80-98fb-5f7ceff98dee" not found'},
                 row: 18
               },
               %{errors: %{"subject#3" => ["can't be blank"]}, row: 21},
               %{errors: %{"published" => ~s'"flase" is invalid'}, row: 26},
               %{errors: %{"id" => "is required"}, row: 28},
               %{
                 errors: %{"accession_number" => ~s'"MISMATCHED_ACCESSION" does not match'},
                 row: 37
               }
             ]
    end
  end

  # The stable ids of every identified item on the work, by kind.
  defp item_ids(work) do
    %{
      description: Enum.map(work.descriptive_metadata.description, & &1.id),
      keywords: Enum.map(work.descriptive_metadata.keywords, & &1.id),
      notes: Enum.map(work.descriptive_metadata.notes, & &1.id),
      related_url: Enum.map(work.descriptive_metadata.related_url, & &1.id)
    }
  end

  # Rewrite one column's cell in every data row of an exported CSV (row 0 is
  # the query row, row 1 the header).
  defp replace_cell(exported_csv, column, fun) do
    [query_row, header | data] = CSV.parse_string(exported_csv, skip_headers: false)
    index = Enum.find_index(header, &(&1 == column))

    data = Enum.map(data, &List.update_at(&1, index, fun))

    [query_row, header | data]
    |> CSV.dump_to_iodata()
    |> IO.iodata_to_binary()
  end

  defp create_job_with_content(content, filename) do
    key = "csv_metadata/#{filename}"

    ExAws.S3.put_object(@upload_bucket, key, content)
    |> ExAws.request!()

    on_exit(fn ->
      ExAws.S3.delete_object(@upload_bucket, key) |> ExAws.request()
    end)

    MetadataUpdateJobs.create_job(%{
      filename: filename,
      source: "s3://#{@upload_bucket}/#{key}",
      user: "validUser"
    })
  end
end
