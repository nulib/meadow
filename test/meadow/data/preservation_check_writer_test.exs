defmodule Meadow.Data.PreservationCheckWriterTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Data.{FileSets, PreservationCheckWriter}
  alias Meadow.Pipeline.Actions.CreatePyramidTiff
  alias Meadow.Utils.Pairtree

  @report_filename "pres_check.csv"

  @preservation_check_bucket Meadow.Config.preservation_check_bucket()
  @preservation_bucket Meadow.Config.preservation_bucket()
  @ingest_bucket Meadow.Config.ingest_bucket()
  @pyramid_bucket Meadow.Config.pyramid_bucket()

  @sha256 "412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90"
  @sha1 "29b05ca3286e06d1031feb6cef7f623d3efd6986"
  @key "copy_file_to_preservation_test/test.tif"
  @content "test/fixtures/coffee.tif"
  @ingest_fixture %{bucket: @ingest_bucket, key: @key, content: File.read!(@content)}
  @preservation_key Pairtree.preservation_path(@sha256)
  @preservation_fixture %{
    bucket: @preservation_bucket,
    key: @preservation_key,
    content: File.read!(@content)
  }

  setup do
    work = work_fixture()

    file_set_1 =
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

    file_set_2 =
      file_set_fixture(%{
        work_id: work.id,
        accession_number: "456",
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

    file_set_3 =
      file_set_fixture(%{
        work_id: work.id,
        accession_number: "789",
        role: %{id: "S", scheme: "FILE_SET_ROLE"},
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

    {:ok, file_set_1: file_set_1, file_set_2: file_set_2, file_set_3: file_set_3}
  end

  describe "generate_report/1" do
    setup %{file_set_1: file_set_1, file_set_2: file_set_2} do
      on_exit(fn ->
        delete_object(@preservation_check_bucket, @report_filename)
        delete_object(@pyramid_bucket, Pairtree.pyramid_path(file_set_1.id))
        delete_object(@pyramid_bucket, Pairtree.pyramid_path(file_set_2.id))
      end)

      :ok
    end

    @describetag s3: [@preservation_fixture]
    test "generates and uploads a preservation check report", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})
      CreatePyramidTiff.process(%{file_set_id: file_set_2.id}, %{})

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 0} =
               PreservationCheckWriter.generate_report(@report_filename)

      assert object_exists?(@preservation_check_bucket, @report_filename)
    end

    @describetag s3: [@preservation_fixture]
    test "records an error if preservation file not found in expected location", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})
      CreatePyramidTiff.process(%{file_set_id: file_set_2.id}, %{})

      FileSets.update_file_set(file_set_2, %{
        core_metadata: %{
          location:
            "s3://#{@preservation_bucket}/d6d3ac3443c6141638faad1ac06c73a4fa355682da9364c5fa863ead4cf2361a"
        }
      })

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 1} =
               PreservationCheckWriter.generate_report(@report_filename)

      assert object_exists?(@preservation_check_bucket, @report_filename)
    end

    @describetag s3: [@preservation_fixture, @ingest_fixture]
    test "records an error if preservation location is not preservation bucket", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})
      CreatePyramidTiff.process(%{file_set_id: file_set_2.id}, %{})

      FileSets.update_file_set(file_set_2, %{
        core_metadata: %{
          location: "s3://#{@ingest_bucket}/#{@key}"
        }
      })

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 1} =
               PreservationCheckWriter.generate_report(@report_filename)

      assert object_exists?(@preservation_check_bucket, @report_filename)
    end

    @describetag s3: [@preservation_fixture]
    test "records an error if pyramid file not found in expected location", %{
      file_set_1: file_set_1
    } do
      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 1} =
               PreservationCheckWriter.generate_report(@report_filename)

      assert object_exists?(@preservation_check_bucket, @report_filename)
    end

    @describetag s3: [@preservation_fixture]
    test "records an error if file set digests are missing", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      FileSets.update_file_set(file_set_1, %{core_metadata: %{digests: nil}})
      FileSets.update_file_set(file_set_2, %{core_metadata: %{digests: %{"sha256" => "badsha"}}})

      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})
      CreatePyramidTiff.process(%{file_set_id: file_set_2.id}, %{})

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 2} =
               PreservationCheckWriter.generate_report(@report_filename)
    end
  end
end
