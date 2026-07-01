defmodule Meadow.Data.CSV.MetadataUpdateJobsTest do
  use Meadow.DataCase
  use Meadow.CSVMetadataUpdateCase
  use Meadow.IndexCase
  use Meadow.GeoNamesCase
  alias Meadow.Data.{CSV.Export, CSV.MetadataUpdateJobs, Indexer, Works}
  alias Meadow.Data.Schemas.{CSV.MetadataUpdateJob, ValueEntry, Work}
  alias Meadow.Repo
  alias Meadow.Search.Document
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
               %{errors: %{"id" => ~s'"0bde5432-0b7b-4f80-98fb-5f7ceff98dee" not found'}, row: 18},
               %{errors: %{"subject#3" => ["can't be blank"]}, row: 21},
               %{errors: %{"published" => ~s'"flase" is invalid'}, row: 26},
               %{errors: %{"id" => "is required"}, row: 28},
               %{errors: %{"accession_number" => ~s'"MISMATCHED_ACCESSION" does not match'}, row: 37}
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
