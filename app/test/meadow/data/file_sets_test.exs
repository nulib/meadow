defmodule Meadow.Data.FileSetsTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Utils.{ChangesetErrors, Pairtree}

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      role: %{id: "A", scheme: "FILE_SET_ROLE"},
      core_metadata: %{
        description: "yes",
        location: "https://example.com",
        original_filename: "test.tiff"
      }
    }

    @invalid_attrs %{accession_number: nil}

    @mediainfo %{
      "mediainfo" => %{
        "tool" => "mediainfo",
        "value" => %{
          "media" => %{
            "track" => [
              %{
                "@type" => "General",
                "Duration" => "1000.999"
              }
            ]
          }
        }
      }
    }

    test "list_file_sets/0 returns all file_sets" do
      file_set_fixture()
      assert length(FileSets.list_file_sets()) == 1
    end

    test "create_file_set/1 with valid data creates a file_set" do
      assert {:ok, %FileSet{} = _file_set} = FileSets.create_file_set(@valid_attrs)
    end

    test "create_file_set/1 with invalid data does not create a file_set" do
      assert {:error, %Ecto.Changeset{}} = FileSets.create_file_set(@invalid_attrs)
    end

    test "delete_file_set/1 deletes a file_set" do
      file_set = file_set_fixture()
      assert {:ok, %FileSet{} = _file_set} = FileSets.delete_file_set(file_set)
      assert Enum.empty?(FileSets.list_file_sets())
    end

    test "update_file_set/2 updates a file_set" do
      file_set = file_set_fixture()

      assert {:ok, %FileSet{} = file_set} =
               FileSets.update_file_set(file_set, %{
                 core_metadata: %{description: "New description"}
               })

      assert file_set.core_metadata.description == "New description"
    end

    test "update_file_set/2 with invalid attributes returns an error" do
      file_set = file_set_fixture()

      assert {:error, %Ecto.Changeset{}} = FileSets.update_file_set(file_set, %{work_id: 123})
    end

    test "updating rank, role or accession_number with update_file_set/2 is not allowed" do
      file_set = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      assert {:ok, %FileSet{} = updated_file_set} =
               FileSets.update_file_set(file_set, %{
                 rank: 123,
                 core_metadata: %{label: "New label"},
                 accession_number: "Unsupported",
                 role: %{id: "P", scheme: "FILE_SET_ROLE"}
               })

      assert updated_file_set.core_metadata.label == "New label"
      assert updated_file_set.role.id == "A"
      assert updated_file_set.accession_number == file_set.accession_number
      assert updated_file_set.rank == file_set.rank
    end

    test "update_file_sets/1 updates multiple file_sets" do
      file_set1 =
        file_set_fixture(%{
          structural_metadata: %{
            type: "WEBVTT",
            value: "WEBVTT - Translation of that film I like\n\n"
          }
        })

      file_set2 = file_set_fixture()

      updates1 = %{id: file_set1.id, core_metadata: %{description: "New description"}}
      updates2 = %{id: file_set2.id, core_metadata: %{label: "New label"}}

      assert {:ok, [file_set1, file_set2]} = FileSets.update_file_sets([updates1, updates2])

      assert file_set1.core_metadata.description == "New description"
      assert file_set2.core_metadata.label == "New label"

      assert file_set1.structural_metadata.type == "WEBVTT"
    end

    test "update_file_sets/1 with bad data returns an error" do
      file_set1 = file_set_fixture()
      file_set2 = file_set_fixture()

      updates1 = %{id: file_set1.id, core_metadata: %{description: 900}}
      updates2 = %{id: file_set2.id, core_metadata: %{label: "New label"}}

      assert {:error, :index_1, %Ecto.Changeset{} = changeset} =
               FileSets.update_file_sets([updates1, updates2])

      refute changeset.valid?

      assert ChangesetErrors.error_details(changeset) == %{
               core_metadata: %{description: [%{error: "is invalid", value: "900"}]}
             }
    end

    test "replace_file_set/1 with new location updates file_set" do
      file_set = file_set_fixture()

      replace_attrs = %{
        id: file_set.id,
        core_metadata: %{
          location: "https://example.com",
          original_filename: "test.tiff"
        }
      }

      assert {:ok, %FileSet{} = file_set} = FileSets.replace_file_set(file_set, replace_attrs)
      assert file_set.core_metadata.location == "https://example.com"
    end

    test "get_file_set!/1 returns a file set by id" do
      file_set = file_set_fixture()
      assert FileSets.get_file_set!(file_set.id) == file_set
    end

    test "get_file_set_by_accession_number!/1 returns a file set by accession_number" do
      file_set = file_set_fixture()
      assert FileSets.get_file_set_by_accession_number!(file_set.accession_number) == file_set
    end

    test "get_file_set_with_work_and_sheet!/1 returns a file set with work and ingest sheet preloaded" do
      file_set = file_set_fixture() |> Repo.preload(:work)
      assert FileSets.get_file_set_with_work_and_sheet!(file_set.id) == file_set
    end

    test "accession_exists?/1 returns true if accession is already taken" do
      file_set = file_set_fixture()

      assert FileSets.accession_exists?(file_set.accession_number) == true
    end

    test "compute_positions/1 dynamically sets position values" do
      assert FileSets.compute_positions([%{position: nil}, %{position: nil}]) == [
               %{position: 0},
               %{position: 1}
             ]
    end
  end

  describe "utilities" do
    test "download_uri_for/1 for an Auxilary file" do
      file_set = file_set_fixture(role: %{id: "X", scheme: "FILE_SET_ROLE"})

      with url <- file_set |> FileSets.download_uri_for() do
        assert url |> String.ends_with?("file-sets/#{file_set.id}/download")
      end
    end

    test "download_uri_for/1 for an Access file" do
      file_set = file_set_fixture(role: %{id: "A", scheme: "FILE_SET_ROLE"})

      with url <- file_set |> FileSets.download_uri_for() do
        assert url |> String.ends_with?("file-sets/#{file_set.id}/download")
      end
    end

    test "download_uri_for/1 for other file (not image, pdf or zip) is null" do
      file_set = file_set_fixture(role: %{id: "P", scheme: "FILE_SET_ROLE"})
      assert is_nil(FileSets.download_uri_for(file_set))
    end

    test "derivative_key/1 for a FileSet" do
      file_set = file_set_fixture(role: %{id: "X", scheme: "FILE_SET_ROLE"})

      with key <- FileSets.derivative_key(file_set) do
        assert key == "derivatives/#{Pairtree.derivative_path(file_set.id)}"
      end
    end

    test "derivative_location/1 for a FileSet" do
      file_set = file_set_fixture(role: %{id: "X", scheme: "FILE_SET_ROLE"})

      with url <- FileSets.derivative_location(file_set) do
        assert url |> String.starts_with?("s3://#{@pyramid_bucket}/")
        assert url |> String.ends_with?(Pairtree.derivative_path(file_set.id))
      end
    end

    test "representative_image_url_for/1 for a video with a poster" do
      file_set = file_set_fixture(%{derivatives: %{"poster" => "poster.tiff"}})

      with uri <- file_set |> FileSets.representative_image_url_for() |> URI.parse() do
        assert uri.host == "localhost"
        assert uri.path == "/iiif/3/posters/#{file_set.id}"
      end
    end

    test "representative_image_url_for/1 for a video without a poster" do
      file_set = file_set_fixture(%{derivatives: nil})
      assert is_nil(FileSets.representative_image_url_for(file_set))
    end

    test "representative_image_url_for/1 for an image" do
      file_set = file_set_fixture(%{derivatives: %{"pyramid_tiff" => "pyramid.tif"}})

      with uri <- file_set |> FileSets.representative_image_url_for() |> URI.parse() do
        assert uri.host == "localhost"
        assert uri.path == "/iiif/3/#{file_set.id}"
      end
    end

    test "streaming_uri_for/1 for a FileSet with a 'P' role" do
      file_set = file_set_fixture(role: %{id: "P", scheme: "FILE_SET_ROLE"})
      assert is_nil(FileSets.streaming_uri_for(file_set))
    end

    test "streaming_uri_for/1 for a FileSet with any role besides 'P'" do
      file_set = file_set_fixture(role: %{id: "A", scheme: "FILE_SET_ROLE"})

      with uri <- file_set |> FileSets.streaming_uri_for() |> URI.parse() do
        assert uri.host == Config.streaming_bucket()
        assert uri.path |> String.length() == 55
      end
    end

    test "pyramid_uri_for/1 for a FileSet" do
      file_set_a = file_set_fixture(
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          mime_type: "image/jpeg",
          location: "s3://foo",
          original_filename: "s3://bar"
        }
      )
      file_set_s = file_set_fixture(role: %{id: "S", scheme: "FILE_SET_ROLE"})
      file_set_p = file_set_fixture(role: %{id: "P", scheme: "FILE_SET_ROLE"})
      file_set_x_image = file_set_fixture(
        role: %{id: "X", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          mime_type: "image/jpeg",
          location: "s3://foo",
          original_filename: "s3://bar"
        }
      )

      file_set_x_pdf =
        file_set_fixture(
          role: %{id: "X", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "application/pdf",
            location: "s3://foo",
            original_filename: "s3://bar"
          }
        )

      file_set_video =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "video/mp4",
            location: "s3://foo",
            original_filename: "s3://bar"
          }
        )

      file_set_audio =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            mime_type: "audio/mpeg",
            location: "s3://foo",
            original_filename: "s3://bar"
          }
        )

      with uri <- file_set_a |> FileSets.pyramid_uri_for() |> URI.parse() do
        assert uri.host == Config.pyramid_bucket()
      end

      assert is_nil(FileSets.pyramid_uri_for(file_set_s))
      assert is_nil(FileSets.pyramid_uri_for(file_set_p))
      assert is_nil(FileSets.pyramid_uri_for(file_set_video))
      assert is_nil(FileSets.pyramid_uri_for(file_set_audio))
      assert is_nil(FileSets.pyramid_uri_for(file_set_x_pdf))

      with uri <- file_set_x_image |> FileSets.pyramid_uri_for() |> URI.parse() do
        assert uri.host == Config.pyramid_bucket()
      end
    end

    test "poster_uri_for/1 for a FileSet with a playlist" do
      file_set = file_set_fixture(
        %{
          core_metadata: %{
            mime_type: "video/mp4",
            location: "s3://foo",
            original_filename: "s3://bar"
        }})

      with url <- file_set |> FileSets.poster_uri_for() do
        assert url |> String.starts_with?("s3://#{@pyramid_bucket}/posters/")
        assert url |> String.ends_with?("-poster.tif")
      end
    end

    test "preservation_location/1 for a FileSet" do
      file_set = file_set_fixture()

      with url <- FileSets.preservation_location(file_set) do
        assert url |> String.starts_with?("s3://#{@preservation_bucket}/")
        assert url |> String.ends_with?(Pairtree.preservation_path(file_set.id))
      end
    end

    test "add_derivatives/3" do
      assert FileSets.add_derivative(%FileSet{derivatives: nil}, "playlist", "test.m3u8") ==
               %{"playlist" => "test.m3u8"}

      assert %FileSet{derivatives: %{"pyramid" => "test.tif"}}
             |> FileSets.add_derivative("playlist", "test.m3u8") ==
               %{"pyramid" => "test.tif", "playlist" => "test.m3u8"}
    end

    test "duration_in_milliseconds/1 for a file set with extracted mediainfo" do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata: @mediainfo
        )

      assert FileSets.duration_in_milliseconds(file_set) == 1_000_999.0
    end

    test "duration_in_milliseconds/1 for a file set with extracted mediainfo but nil duration" do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata:
            @mediainfo
            |> put_in(["mediainfo", "value", "media", "track", Access.at(0), "Duration"], nil)
        )

      assert is_nil(FileSets.duration_in_milliseconds(file_set))
    end

    test "duration_in_milliseconds/1 for a file set with extracted mediainfo but no tracks" do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata:
            @mediainfo
            |> put_in(["mediainfo", "value", "media", "track"], [])
        )

      assert is_nil(FileSets.duration_in_milliseconds(file_set))
    end

    test "duration_in_milliseconds/1 for a file set without extracted mediainfo" do
      file_set = file_set_fixture()

      assert is_nil(FileSets.duration_in_milliseconds(file_set))
    end

    test "aspect_ratio/1 calculated via extracted metadata" do
      file_set =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata: %{
            "exif" => %{"value" => %{"ImageWidth" => 249, "ImageHeight" => 103}}
          }
        )

      assert FileSets.aspect_ratio(file_set) == 2.41747

      file_set_without_extracted_metadata = file_set_fixture()
      assert is_nil(FileSets.aspect_ratio(file_set_without_extracted_metadata))

      file_set_with_only_height =
        file_set_fixture(
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          extracted_metadata: %{
            "exif" => %{"value" => %{"ImageWidth" => 249}}
          }
        )

      assert is_nil(FileSets.aspect_ratio(file_set_with_only_height))
    end
  end

  describe "distribution_streaming_uri_for/1" do
    setup do
      {:ok, %{file_set: file_set_fixture()}}
    end

    test "for a FileSet with any role besides 'P'", %{file_set: file_set} do
      with url <- file_set |> FileSets.distribution_streaming_uri_for() do
        assert url |> String.starts_with?(Config.streaming_url())
        assert url |> String.ends_with?("/bar.m3u8")
      end
    end

    test "with nil derivatives", %{file_set: file_set} do
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: nil})
      assert is_nil(FileSets.distribution_streaming_uri_for(file_set))
    end

    test "with nil playlist", %{file_set: file_set} do
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: %{"playlist" => nil}})
      assert is_nil(FileSets.distribution_streaming_uri_for(file_set))
    end

    test "with empty playlist", %{file_set: file_set} do
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: %{"playlist" => ""}})
      assert is_nil(FileSets.distribution_streaming_uri_for(file_set))
    end

    test "with unparseable playlist", %{file_set: file_set} do
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: %{"playlist" => 42}})
      assert is_nil(FileSets.distribution_streaming_uri_for(file_set))
    end
  end

  describe "group_with functionality" do
    test "update_file_set/2 with valid group_with value" do
      file_set1 = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      file_set2 = file_set_fixture(%{work_id: file_set1.work_id, role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      assert {:ok, %FileSet{} = updated_file_set} =
               FileSets.update_file_set(file_set1, %{group_with: file_set2.id})

      assert updated_file_set.group_with == file_set2.id
    end

    test "update_file_set/2 rejects group_with when source file set doesn't have role 'A'" do
      file_set1 = file_set_fixture(%{role: %{id: "P", scheme: "FILE_SET_ROLE"}})
      file_set2 = file_set_fixture(%{work_id: file_set1.work_id, role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      assert {:error, changeset} = FileSets.update_file_set(file_set1, %{group_with: file_set2.id})
      assert %{group_with: ["Only file sets with role 'Access (A)' can be grouped"]} = errors_on(changeset)
    end

    test "update_file_set/2 rejects group_with when target file set doesn't have role 'A'" do
      file_set1 = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      file_set2 = file_set_fixture(%{work_id: file_set1.work_id, role: %{id: "P", scheme: "FILE_SET_ROLE"}})

      assert {:error, changeset} = FileSets.update_file_set(file_set1, %{group_with: file_set2.id})
      assert %{group_with: ["Target file set must have role 'Access (A)'"]} = errors_on(changeset)
    end

    test "update_file_set/2 rejects group_with when target file set doesn't exist" do
      file_set = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      non_existent_id = Ecto.UUID.generate()

      assert {:error, changeset} = FileSets.update_file_set(file_set, %{group_with: non_existent_id})
      assert %{group_with: ["Target file set not found"]} = errors_on(changeset)
    end

    test "update_file_set/2 rejects group_with when target file set belongs to different work" do
      file_set1 = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      work = work_fixture()
      file_set2 = file_set_fixture(%{work_id: work.id, role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      assert {:error, changeset} = FileSets.update_file_set(file_set1, %{group_with: file_set2.id})
      assert %{group_with: ["Target file set belongs to a different work"]} = errors_on(changeset)
    end

    test "update_file_set/2 rejects group_with when target file set already has a group_with value" do
      file_set1 = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      file_set2 = file_set_fixture(%{work_id: file_set1.work_id, role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      file_set3 = file_set_fixture(%{work_id: file_set1.work_id, role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      # First set file_set2 to group with file_set3
      assert {:ok, %FileSet{}} = FileSets.update_file_set(file_set2, %{group_with: file_set3.id})

      # Now try to set file_set1 to group with file_set2 (which already has a group_with)
      assert {:error, changeset} = FileSets.update_file_set(file_set1, %{group_with: file_set2.id})
      assert %{group_with: ["Target file set already has a group_with value"]} = errors_on(changeset)
    end

    test "create_file_set/1 with valid group_with value" do
      existing_file_set = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      attrs = Map.merge(@valid_attrs, %{
        work_id: existing_file_set.work_id,
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        group_with: existing_file_set.id
      })

      assert {:ok, %FileSet{} = file_set} = FileSets.create_file_set(attrs)
      assert file_set.group_with == existing_file_set.id
    end
  end
end
