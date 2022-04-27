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
  @md5 "85062e8c916f55ae0c514cb0732cfb1f"
  @key "copy_file_to_preservation_test/test.tif"
  @content "test/fixtures/coffee.tif"
  @ingest_fixture %{bucket: @ingest_bucket, key: @key, content: File.read!(@content)}
  @preservation_key Pairtree.preservation_path(@sha256)
  @preservation_fixture %{
    bucket: @preservation_bucket,
    key: @preservation_key,
    content: File.read!(@content)
  }

  describe "generate_report/1" do
    @describetag s3: [@preservation_fixture]

    setup do
      image_work = work_fixture(%{work_type: %{id: "IMAGE", scheme: "work_type"}})

      file_set_1 =
        file_set_fixture(%{
          work_id: image_work.id,
          accession_number: "123",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            digests: %{
              "sha256" => @sha256,
              "sha1" => @sha1,
              "md5" => @md5
            },
            location: "s3://#{@preservation_bucket}/#{Pairtree.preservation_path(@sha256)}",
            mime_type: "image/tiff",
            original_filename: "test.tif"
          }
        })

      file_set_2 =
        file_set_fixture(%{
          work_id: image_work.id,
          accession_number: "456",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            digests: %{
              "sha256" => @sha256,
              "sha1" => @sha1,
              "md5" => @md5
            },
            location: "s3://#{@preservation_bucket}/#{Pairtree.preservation_path(@sha256)}",
            mime_type: "image/tiff",
            original_filename: "test.tif"
          }
        })

      file_set_3 =
        file_set_fixture(%{
          work_id: image_work.id,
          accession_number: "789",
          role: %{id: "S", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            digests: %{
              "sha256" => @sha256,
              "sha1" => @sha1,
              "md5" => @md5
            },
            location: "s3://#{@preservation_bucket}/#{Pairtree.preservation_path(@sha256)}",
            mime_type: "image/tiff",
            original_filename: "test.tif"
          }
        })

      on_exit(fn ->
        delete_object(@preservation_check_bucket, @report_filename)
        delete_object(@pyramid_bucket, Pairtree.pyramid_path(file_set_1.id))
        delete_object(@pyramid_bucket, Pairtree.pyramid_path(file_set_2.id))
      end)

      {:ok, file_set_1: file_set_1, file_set_2: file_set_2, file_set_3: file_set_3}
    end

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

    test "records an error if pyramid file not found in expected location", %{
      file_set_1: file_set_1
    } do
      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 1} =
               PreservationCheckWriter.generate_report(@report_filename)

      assert object_exists?(@preservation_check_bucket, @report_filename)
    end

    test "records an error if file set digests are missing", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      FileSets.update_file_set(file_set_1, %{core_metadata: %{digests: nil}})

      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})
      CreatePyramidTiff.process(%{file_set_id: file_set_2.id}, %{})

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 1} =
               PreservationCheckWriter.generate_report(@report_filename)
    end

    test "succeeds if at least one valid digest is present", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      FileSets.update_file_set(file_set_1, %{core_metadata: %{digests: %{"md5" => @md5}}})

      CreatePyramidTiff.process(%{file_set_id: file_set_1.id}, %{})
      CreatePyramidTiff.process(%{file_set_id: file_set_2.id}, %{})

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 0} =
               PreservationCheckWriter.generate_report(@report_filename)
    end

    test "records an error if any existing digest is invalid", %{
      file_set_1: file_set_1,
      file_set_2: file_set_2
    } do
      FileSets.update_file_set(file_set_1, %{
        core_metadata: %{digests: %{"md5" => @md5, "sha1" => "badsha"}}
      })

      FileSets.update_file_set(file_set_2, %{
        core_metadata: %{digests: %{"md5" => @md5, "sha256" => @sha1}}
      })

      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 2} =
               PreservationCheckWriter.generate_report(@report_filename)
    end
  end

  describe "generate_report/1 with video file sets" do
    setup do
      video_work = work_fixture(%{work_type: %{id: "VIDEO", scheme: "work_type"}})

      video_access_file_set =
        file_set_fixture(%{
          work_id: video_work.id,
          accession_number: "101112",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            digests: %{
              "sha256" => @sha256,
              "sha1" => @sha1,
              "md5" => @md5
            },
            location: "s3://#{@preservation_bucket}/#{Pairtree.preservation_path(@sha256)}",
            mime_type: "video/mp4",
            original_filename: "test.mp4"
          }
        })

      {:ok, file_set: video_access_file_set}
    end

    @describetag s3: [@preservation_fixture]
    test "does not record an error if video access file set pyramids are missing", %{
      file_set: _file_set
    } do
      assert {:ok, "s3://test-preservation-checks/pres_check.csv", 0} =
               PreservationCheckWriter.generate_report(@report_filename)
    end
  end
end
