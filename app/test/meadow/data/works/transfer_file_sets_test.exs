defmodule Meadow.Data.Works.TransferFileSetsTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Data.Works.TransferFileSets
  alias Meadow.Repo

  describe "transfer/2" do
    setup do
      from_work =
        work_with_file_sets_fixture(5, %{}, %{
          core_metadata: %{
            original_filename: "From Work",
            location: "From Work"
          }
        })

      to_work =
        work_with_file_sets_fixture(3, %{}, %{
          core_metadata: %{
            original_filename: "To Work",
            location: "To Work"
          }
        })

      {:ok, from_work_id: from_work.id, to_work_id: to_work.id}
    end

    test "swaps all file sets from one work to another and deletes the empty work", %{
      from_work_id: from_work_id,
      to_work_id: to_work_id
    } do
      assert {:ok, %Work{id: to_work_id}} = TransferFileSets.transfer(from_work_id, to_work_id)
      refute Works.get_work(from_work_id)

      assert_rank_ordering_valid(to_work_id)
    end

    test "does not allow transferring file sets from one work type to another" do
      from_work =
        work_with_file_sets_fixture(1, %{work_type: %{id: "IMAGE", scheme: "work_type"}})

      from_work_id = from_work.id
      to_work = work_with_file_sets_fixture(1, %{work_type: %{id: "AUDIO", scheme: "work_type"}})
      to_work_id = to_work.id

      assert {:error, "Checking work types: work types do not match (no changes were made)"} =
               TransferFileSets.transfer(from_work_id, to_work_id)

      reloaded_from_work = Works.get_work!(from_work_id) |> Repo.preload(:file_sets)
      reloaded_to_work = Works.get_work!(to_work_id) |> Repo.preload(:file_sets)

      assert Enum.map(from_work.file_sets, & &1.id) ==
               Enum.map(reloaded_from_work.file_sets, & &1.id)

      assert Enum.map(to_work.file_sets, & &1.id) == Enum.map(reloaded_to_work.file_sets, & &1.id)
    end

    test "handles work retrieval errors for 'from' work", %{to_work_id: to_work_id} do
      from_work_id = Ecto.UUID.generate()

      assert {:error, "Fetching 'from' work: work not found (no changes were made)"} =
               TransferFileSets.transfer(from_work_id, to_work_id)
    end

    test "handles work retrieval errors for 'to' work", %{
      from_work_id: from_work_id
    } do
      to_work_id = Ecto.UUID.generate()

      assert {:error, "Fetching 'to' work: work not found (no changes were made)"} =
               TransferFileSets.transfer(from_work_id, to_work_id)
    end
  end

  describe "transfer_subset/1" do
    setup do
      source_work =
        work_with_file_sets_fixture(5, %{work_type: %{id: "IMAGE", scheme: "work_type"}})

      target_work =
        work_with_file_sets_fixture(2, %{work_type: %{id: "IMAGE", scheme: "work_type"}})

      fileset_ids = Enum.map(Enum.take(source_work.file_sets, 3), & &1.id)

      {:ok, source_work: source_work, target_work: target_work, fileset_ids: fileset_ids}
    end

    test "transfers a subset of filesets to existing work", %{
      target_work: target_work,
      fileset_ids: fileset_ids
    } do
      args = %{
        fileset_ids: fileset_ids,
        create_work: false,
        accession_number: target_work.accession_number
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 3
      assert Enum.all?(fileset_ids, &(&1 in transferred_ids))
    end

    test "creates new work and transfers filesets", %{fileset_ids: fileset_ids} do
      args = %{
        fileset_ids: fileset_ids,
        create_work: true,
        work_attributes: %{
          accession_number: "NEW_WORK_123",
          work_type: "IMAGE",
          descriptive_metadata: %{
            title: "New Test Work"
          }
        }
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids, created_work_id: work_id}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 3
      assert work_id != nil
      assert Enum.all?(fileset_ids, &(&1 in transferred_ids))

      new_work = Works.get_work!(work_id)
      assert new_work.accession_number == "NEW_WORK_123"
      assert new_work.descriptive_metadata.title == "New Test Work"
    end

    test "fails with empty fileset_ids" do
      args = %{
        fileset_ids: [],
        create_work: false,
        accession_number: "SOME_WORK"
      }

      assert {:error, "Fileset IDs cannot be empty"} = TransferFileSets.transfer_subset(args)
    end

    test "fails when target work does not exist" do
      args = %{
        fileset_ids: ["some-id"],
        create_work: false,
        accession_number: "NONEXISTENT"
      }

      assert {:error, "No work found with accession NONEXISTENT"} =
               TransferFileSets.transfer_subset(args)
    end

    test "fails when required accession_number is missing for existing work" do
      args = %{
        fileset_ids: ["some-id"],
        create_work: false
      }

      assert {:error, "Accession number is required when transferring to existing work"} =
               TransferFileSets.transfer_subset(args)
    end

    test "fails when create_work: true is missing accession_number", %{fileset_ids: fileset_ids} do
      args = %{
        fileset_ids: Enum.take(fileset_ids, 1),
        create_work: true,
        work_attributes: %{
          work_type: "IMAGE",
          descriptive_metadata: %{
            title: "Missing Accession Work"
          }
        }
      }

      assert {:error, "accession_number is required when creating a new work"} =
               TransferFileSets.transfer_subset(args)
    end

    test "fails when create_work: true is missing work_type", %{fileset_ids: fileset_ids} do
      args = %{
        fileset_ids: Enum.take(fileset_ids, 1),
        create_work: true,
        work_attributes: %{
          accession_number: "MISSING_TYPE_WORK",
          descriptive_metadata: %{
            title: "Missing Type Work"
          }
        }
      }

      assert {:error, "work_type is required when creating a new work"} =
               TransferFileSets.transfer_subset(args)
    end

    test "fails when create_work: true is missing both required fields", %{
      fileset_ids: fileset_ids
    } do
      args = %{
        fileset_ids: Enum.take(fileset_ids, 1),
        create_work: true,
        work_attributes: %{
          descriptive_metadata: %{
            title: "Missing Both Fields Work"
          }
        }
      }

      assert {:error, "accession_number and work_type are required when creating a new work"} =
               TransferFileSets.transfer_subset(args)
    end

    test "fails when create_work: false has empty accession_number" do
      args = %{
        fileset_ids: ["some-id"],
        create_work: false,
        accession_number: ""
      }

      assert {:error, "Accession number is required when transferring to existing work"} =
               TransferFileSets.transfer_subset(args)
    end

    test "fails when filesets do not exist" do
      non_existent_ids = [Ecto.UUID.generate(), Ecto.UUID.generate()]

      args = %{
        fileset_ids: non_existent_ids,
        create_work: true,
        work_attributes: %{
          accession_number: "NEW_WORK_123",
          work_type: "IMAGE",
          descriptive_metadata: %{
            title: "New Test Work"
          }
        }
      }

      assert {:error, error_msg} = TransferFileSets.transfer_subset(args)
      assert String.contains?(error_msg, "Filesets not found:")
    end

    test "creates work with comprehensive metadata", %{fileset_ids: fileset_ids} do
      collection = collection_fixture()

      args = %{
        fileset_ids: Enum.take(fileset_ids, 2),
        create_work: true,
        work_attributes: %{
          accession_number: "COMPREHENSIVE_WORK",
          work_type: "IMAGE",
          collection_id: collection.id,
          published: false,
          visibility: %{id: "RESTRICTED", scheme: "visibility"},
          descriptive_metadata: %{
            title: "Sample Work Title",
            description: ["Work description"],
            abstract: ["Work abstract"],
            alternate_title: ["Work's alternate title"],
            keywords: ["keyword1", "keyword2"],
            identifier: ["work_identifier"],
            catalog_key: ["work_cd"],
            box_name: ["Box name"],
            box_number: ["Box number"],
            folder_name: ["Folder name"],
            folder_number: ["Folder number"],
            series: ["Series name"],
            physical_description_material: ["Material description"],
            physical_description_size: ["Size description"],
            publisher: ["Publisher name"],
            rights_holder: ["Rights holder"],
            terms_of_use: "Terms of use statement",
            license: %{id: "http://creativecommons.org/publicdomain/mark/1.0/", scheme: "license"},
            rights_statement: %{
              id: "http://rightsstatements.org/vocab/NKC/1.0/",
              scheme: "rights_statement"
            },
            date_created: [%{edtf: "2025", humanized: "2025"}]
          },
          administrative_metadata: %{
            project_name: ["Project name"],
            project_manager: ["Project manager"],
            project_desc: ["Project description"],
            project_proposer: ["Project proposer"],
            project_task_number: ["Task number"],
            project_cycle: "Project cycle",
            library_unit: %{id: "MUSIC_LIBRARY", scheme: "library_unit"},
            preservation_level: %{id: "1", scheme: "preservation_level"},
            status: %{id: "IN PROGRESS", scheme: "status"}
          }
        }
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids, created_work_id: work_id}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 2
      assert work_id != nil

      new_work = Works.get_work!(work_id)
      assert new_work.accession_number == "COMPREHENSIVE_WORK"
      assert new_work.collection_id == collection.id
      assert new_work.published == false
      assert new_work.visibility.id == "RESTRICTED"
      assert new_work.descriptive_metadata.title == "Sample Work Title"
      assert new_work.descriptive_metadata.description == ["Work description"]
      assert new_work.administrative_metadata.project_name == ["Project name"]
      assert new_work.administrative_metadata.library_unit.id == "MUSIC_LIBRARY"
    end

    test "deletes source work when it becomes empty after transfer (default behavior)", %{
      source_work: source_work,
      target_work: target_work
    } do
      # Transfer all filesets from source to target work
      all_fileset_ids = Enum.map(source_work.file_sets, & &1.id)

      args = %{
        fileset_ids: all_fileset_ids,
        create_work: false,
        accession_number: target_work.accession_number
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 5
      assert Enum.all?(all_fileset_ids, &(&1 in transferred_ids))

      # Source work should be deleted since it's now empty
      refute Works.get_work(source_work.id)

      # Target work should have all filesets
      updated_target = Works.with_file_sets(target_work.id)
      # 2 original + 5 transferred
      assert length(updated_target.file_sets) == 7
    end

    test "does not delete source work when delete_empty_works is false", %{
      source_work: source_work,
      target_work: target_work
    } do
      # Transfer all filesets from source to target work
      all_fileset_ids = Enum.map(source_work.file_sets, & &1.id)

      args = %{
        fileset_ids: all_fileset_ids,
        create_work: false,
        accession_number: target_work.accession_number,
        delete_empty_works: false
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 5
      assert Enum.all?(all_fileset_ids, &(&1 in transferred_ids))

      # Source work should still exist even though it's empty
      empty_source_work = Works.with_file_sets(source_work.id)
      assert empty_source_work != nil
      assert Enum.empty?(empty_source_work.file_sets)

      # Target work should have all filesets
      updated_target = Works.with_file_sets(target_work.id)
      # 2 original + 5 transferred
      assert length(updated_target.file_sets) == 7
    end

    test "does not delete source work when it still has filesets after partial transfer", %{
      source_work: source_work,
      target_work: target_work
    } do
      # Transfer only some filesets from source to target work
      partial_fileset_ids = Enum.take(Enum.map(source_work.file_sets, & &1.id), 3)

      args = %{
        fileset_ids: partial_fileset_ids,
        create_work: false,
        accession_number: target_work.accession_number
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 3
      assert Enum.all?(partial_fileset_ids, &(&1 in transferred_ids))

      # Source work should still exist since it has remaining filesets
      remaining_source_work = Works.with_file_sets(source_work.id)
      assert remaining_source_work != nil
      # 5 original - 3 transferred
      assert length(remaining_source_work.file_sets) == 2

      # Target work should have transferred filesets
      updated_target = Works.with_file_sets(target_work.id)
      # 2 original + 3 transferred
      assert length(updated_target.file_sets) == 5
    end

    test "deletes multiple source works when they become empty after transfer" do
      # Create two source works with filesets
      source_work_1 =
        work_with_file_sets_fixture(2, %{work_type: %{id: "IMAGE", scheme: "work_type"}})

      source_work_2 =
        work_with_file_sets_fixture(3, %{work_type: %{id: "IMAGE", scheme: "work_type"}})

      target_work =
        work_with_file_sets_fixture(1, %{work_type: %{id: "IMAGE", scheme: "work_type"}})

      # Get all filesets from both source works
      all_fileset_ids =
        Enum.map(source_work_1.file_sets, & &1.id) ++
          Enum.map(source_work_2.file_sets, & &1.id)

      args = %{
        fileset_ids: all_fileset_ids,
        create_work: false,
        accession_number: target_work.accession_number
      }

      assert {:ok, %{transferred_fileset_ids: transferred_ids}} =
               TransferFileSets.transfer_subset(args)

      assert length(transferred_ids) == 5
      assert Enum.all?(all_fileset_ids, &(&1 in transferred_ids))

      # Both source works should be deleted since they're now empty
      refute Works.get_work(source_work_1.id)
      refute Works.get_work(source_work_2.id)

      # Target work should have all filesets
      updated_target = Works.with_file_sets(target_work.id)
      # 1 original + 5 transferred
      assert length(updated_target.file_sets) == 6
    end
  end

  defp assert_rank_ordering_valid(to_work_id) do
    Enum.each(["A", "P", "S", "X"], fn role ->
      file_sets = Works.with_file_sets(to_work_id, role).file_sets |> Enum.sort_by(& &1.rank)

      {to_work_file_sets, from_work_file_sets} =
        Enum.split_with(file_sets, fn fs ->
          fs.core_metadata.location == "To Work"
        end)

      ordered_file_sets = to_work_file_sets ++ from_work_file_sets

      rank_ordering_valid =
        ordered_file_sets
        |> Enum.map(& &1.rank)
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.all?(fn [a, b] -> a < b end)

      assert rank_ordering_valid, "Rank ordering is not valid for role #{role}"
    end)
  end
end
