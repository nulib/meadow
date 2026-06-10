defmodule Meadow.ArchivesSpace.DigitalTest do
  use Meadow.DataCase

  alias Meadow.ArchivesSpace.{Client, Digital, MockServer}

  setup do
    MockServer.reset()
    Client.invalidate_session()

    # Stub the image store so the tests don't reach the network or S3.
    Application.put_env(:meadow, :archives_space_image_store, fn _uri, _key -> :ok end)
    on_exit(fn -> Application.delete_env(:meadow, :archives_space_image_store) end)

    :ok
  end

  describe "ingest_file_sets/2" do
    test "builds access file sets from an archival object's digital object images" do
      digital_object =
        MockServer.create_digital_object(2, %{
          "file_versions" => [
            %{"file_uri" => "https://images.example.edu/poster-1.tif", "publish" => true}
          ]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/1",
        "instances" => [MockServer.digital_object_instance(digital_object)]
      }

      assert {[file_set], nil} = Digital.ingest_file_sets(archival_object, "aspace:ref1")
      assert file_set.accession_number == "aspace:ref1:0"
      assert file_set.role == %{id: "A", scheme: "file_set_role"}
      assert file_set.core_metadata.original_filename == "poster-1.tif"
      assert file_set.core_metadata.label == "poster-1.tif"
      assert file_set.core_metadata.location =~ "/archivesspace/aspace_ref1/poster-1.tif"
    end

    test "handles multiple digital objects and file versions" do
      do_a =
        MockServer.create_digital_object(2, %{
          "file_versions" => [%{"file_uri" => "https://images.example.edu/a.tif"}]
        })

      do_b =
        MockServer.create_digital_object(2, %{
          "file_versions" => [
            %{"file_uri" => "https://images.example.edu/b1.tif"},
            %{"file_uri" => "https://images.example.edu/b2.tif"}
          ]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/2",
        "instances" => [
          MockServer.digital_object_instance(do_a),
          MockServer.digital_object_instance(do_b)
        ]
      }

      assert {file_sets, nil} = Digital.ingest_file_sets(archival_object, "aspace:ref2")
      assert length(file_sets) == 3
      assert Enum.map(file_sets, & &1.accession_number) |> Enum.uniq() |> length() == 3
    end

    test "returns no file sets when the archival object has no digital objects" do
      archival_object = %{"uri" => "/repositories/2/archival_objects/3", "instances" => []}
      assert Digital.ingest_file_sets(archival_object, "aspace:ref3") == {[], nil}
    end

    test "skips file versions without a file_uri" do
      digital_object =
        MockServer.create_digital_object(2, %{
          "file_versions" => [%{"use_statement" => "image-thumbnail"}]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/4",
        "instances" => [MockServer.digital_object_instance(digital_object)]
      }

      assert Digital.ingest_file_sets(archival_object, "aspace:ref4") == {[], nil}
    end

    test "skips images that fail to store" do
      Application.put_env(:meadow, :archives_space_image_store, fn _uri, _key -> :error end)

      digital_object =
        MockServer.create_digital_object(2, %{
          "file_versions" => [%{"file_uri" => "https://images.example.edu/x.tif"}]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/5",
        "instances" => [MockServer.digital_object_instance(digital_object)]
      }

      assert Digital.ingest_file_sets(archival_object, "aspace:ref5") == {[], nil}
    end

    test "marks the file version flagged is_representative as representative" do
      digital_object =
        MockServer.create_digital_object(2, %{
          "file_versions" => [
            %{"file_uri" => "https://images.example.edu/a.tif"},
            %{"file_uri" => "https://images.example.edu/b.tif", "is_representative" => true}
          ]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/6",
        "instances" => [MockServer.digital_object_instance(digital_object)]
      }

      assert {_file_sets, "aspace:rep1:1"} =
               Digital.ingest_file_sets(archival_object, "aspace:rep1")
    end

    test "falls back to the representative instance when no file version is flagged" do
      do_a =
        MockServer.create_digital_object(2, %{
          "file_versions" => [%{"file_uri" => "https://images.example.edu/a.tif"}]
        })

      do_b =
        MockServer.create_digital_object(2, %{
          "file_versions" => [%{"file_uri" => "https://images.example.edu/b.tif"}]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/7",
        "instances" => [
          MockServer.digital_object_instance(do_a),
          Map.put(MockServer.digital_object_instance(do_b), "is_representative", true)
        ]
      }

      assert {_file_sets, "aspace:rep2:1"} =
               Digital.ingest_file_sets(archival_object, "aspace:rep2")
    end

    test "a flagged file version outranks a merely-representative instance" do
      do_a =
        MockServer.create_digital_object(2, %{
          "file_versions" => [
            %{"file_uri" => "https://images.example.edu/a.tif", "is_representative" => true}
          ]
        })

      do_b =
        MockServer.create_digital_object(2, %{
          "file_versions" => [%{"file_uri" => "https://images.example.edu/b.tif"}]
        })

      archival_object = %{
        "uri" => "/repositories/2/archival_objects/8",
        "instances" => [
          MockServer.digital_object_instance(do_a),
          Map.put(MockServer.digital_object_instance(do_b), "is_representative", true)
        ]
      }

      assert {_file_sets, "aspace:rep3:0"} =
               Digital.ingest_file_sets(archival_object, "aspace:rep3")
    end
  end
end
