defmodule Meadow.Data.PreservationChecksTest do
  use ExUnit.Case
  use Meadow.DataCase
  use Meadow.S3Case

  import Assertions
  import ExUnit.CaptureLog

  alias Meadow.Config
  alias Meadow.Data.PreservationChecks
  alias Meadow.Utils.Pairtree

  @preservation_bucket Config.preservation_bucket()
  @preservation_check_bucket Config.preservation_check_bucket()
  @sha1 "29b05ca3286e06d1031feb6cef7f623d3efd6986"
  @sha256 "412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90"

  setup do
    work = work_fixture()

    file_set_fixture(%{
      work_id: work.id,
      accession_number: "123",
      role: %{id: "A", scheme: "FILE_SET_ROLE"},
      metadata: %{
        digests: %{
          "sha256" => @sha256,
          "sha1" => @sha1
        },
        location: "s3://#{@preservation_bucket}/#{Pairtree.preservation_path(@sha256)}",
        mime_type: "image/tiff",
        original_filename: "test.tif"
      }
    })

    {:ok, %{}}
  end

  test "start_job/0" do
    assert PreservationChecks.list_jobs() |> length() == 0

    logged =
      capture_log(fn ->
        assert Logger.enabled?(self())

        assert_async(timeout: 3000, sleep_time: 150) do
          assert {:ok, _job} = PreservationChecks.start_job()
          assert PreservationChecks.list_jobs() |> length() == 1
          check = PreservationChecks.get_last_job()
          assert check.status == "complete"
        end
      end)

    assert logged |> String.contains?("Determining whether to run preservation check")
    assert logged |> String.contains?("Starting preservation check")
    assert logged |> String.contains?("Preservation check complete")

    jobs = PreservationChecks.list_jobs()

    on_exit(fn ->
      jobs
      |> Enum.each(fn j -> delete_object(@preservation_check_bucket, j.filename) end)
    end)
  end
end
