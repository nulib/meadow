defmodule Meadow.Data.PreservationChecksTest do
  use Meadow.DataCase
  use Meadow.S3Case

  import ExUnit.CaptureLog

  alias Meadow.Data.PreservationChecks
  alias Meadow.Utils.Pairtree

  @sha1 "29b05ca3286e06d1031feb6cef7f623d3efd6986"
  @sha256 "412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90"

  setup do
    work = work_fixture()

    file_set_fixture(%{
      work_id: work.id,
      accession_number: "123",
      role: %{id: "A", scheme: "FILE_SET_ROLE"},
      core_metadata: %{
        digests: %{
          "sha256" => @sha256,
          "sha1" => @sha1
        },
        location: "s3://#{@preservation_bucket}/#{Pairtree.preservation_path(@sha256)}",
        mime_type: "image/tiff",
        original_filename: "test.tif"
      }
    })

    on_exit(fn -> empty_bucket(@preservation_check_bucket) end)

    {:ok, %{}}
  end

  test "start_job/0 starts a preservation check job" do
    assert PreservationChecks.list_jobs() |> length() == 0

    logged =
      capture_log(fn ->
        assert Logger.enabled?(self())

        assert {:ok, _job} = PreservationChecks.start_job()
      end)

    assert PreservationChecks.list_jobs() |> length() == 1

    assert logged |> String.contains?("Starting preservation check")
    assert logged |> String.contains?("Preservation check complete")
  end

  test "start_job/0 will not start a new job if one is already active" do
    assert PreservationChecks.list_jobs() |> length() == 0

    PreservationChecks.create_job(%{active: true})

    assert PreservationChecks.list_jobs() |> length() == 1

    logged =
      capture_log(fn ->
        assert Logger.enabled?(self())
        PreservationChecks.start_job()
      end)

    assert logged |> String.contains?("Active preservation check already running")

    assert PreservationChecks.list_jobs() |> length() == 1
  end
end
