defmodule MeadowWeb.Schema.Mutation.TransferFileSetsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/TransferFileSets.gql")

  describe "mutation" do
    setup do
      work1 = work_with_file_sets_fixture(3, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      work2 = work_with_file_sets_fixture(3, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      {:ok, %{work1: work1, work2: work2}}
    end

    test "transfers file sets from one work to another", %{work1: work1, work2: work2} do
      result =
        query_gql(
          variables: %{"fromWorkId" => work1.id, "toWorkId" => work2.id},
          context: gql_context()
        )

      assert {:ok, %{data: %{"transferFileSets" => %{"id" => returned_id}}}} = result
      assert returned_id == work2.id
    end

    test "returns error for non-existent from work", %{work2: work2} do
      fake_id = Ecto.UUID.generate()

      result =
        query_gql(
          variables: %{"fromWorkId" => fake_id, "toWorkId" => work2.id},
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      assert String.contains?(error_message, "work not found")
    end

    test "returns error for non-existent to work", %{work1: work1} do
      fake_id = Ecto.UUID.generate()

      result =
        query_gql(
          variables: %{"fromWorkId" => work1.id, "toWorkId" => fake_id},
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      assert String.contains?(error_message, "work not found")
    end

    test "returns error for mismatched work types" do
      work1 = work_with_file_sets_fixture(1, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      work2 = work_with_file_sets_fixture(1, %{work_type: %{id: "AUDIO", scheme: "work_type"}})

      result =
        query_gql(
          variables: %{"fromWorkId" => work1.id, "toWorkId" => work2.id},
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      assert String.contains?(error_message, "work types")
    end
  end

  describe "authorization" do
    test "viewers are not authoried to update file set order" do
      work = work_with_file_sets_fixture(1)
      work2 = work_with_file_sets_fixture(1)

      result =
        query_gql(
          variables: %{"fromWorkId" => work.id, "toWorkId" => work2.id},
          context: %{current_user: %{role: :user}}
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end
  end
end

defmodule MeadowWeb.Schema.Mutation.TransferFileSetsTest.Subset do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/TransferFileSetsSubset.gql")

  describe "transfer_file_sets_subset mutation" do
    setup do
      work1 = work_with_file_sets_fixture(3, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      work2 = work_with_file_sets_fixture(2, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      fileset_ids = Enum.map(Enum.take(work1.file_sets, 2), & &1.id)
      {:ok, %{work1: work1, work2: work2, fileset_ids: fileset_ids}}
    end

    test "transfers subset to existing work", %{work2: work2, fileset_ids: fileset_ids} do
      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => false,
            "accessionNumber" => work2.accession_number
          },
          context: gql_context()
        )

      assert {:ok,
              %{
                data: %{
                  "transfer_file_sets_subset" => %{
                    "transferredFilesetIds" => transferred_ids,
                    "createdWorkId" => nil
                  }
                }
              }} = result

      assert length(transferred_ids) == 2
    end

    test "creates new work and transfers filesets", %{fileset_ids: fileset_ids} do
      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => true,
            "workAttributes" => %{
              "accessionNumber" => "NEW_WORK_TEST",
              "workType" => "IMAGE",
              "visibility" => %{"id" => "OPEN", "scheme" => "VISIBILITY"},
              "descriptiveMetadata" => %{
                "title" => "Test New Work"
              }
            }
          },
          context: gql_context()
        )

      assert {:ok,
              %{
                data: %{
                  "transfer_file_sets_subset" => %{
                    "transferredFilesetIds" => transferred_ids,
                    "createdWorkId" => work_id
                  }
                }
              }} = result

      assert length(transferred_ids) == 2
      assert work_id != nil
    end

    test "returns error for empty fileset_ids" do
      result =
        query_gql(
          variables: %{
            "filesetIds" => [],
            "createWork" => false,
            "accessionNumber" => "SOME_WORK"
          },
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      assert String.contains?(error_message, "Fileset IDs cannot be empty")
    end

    test "returns error for invalid fileset_ids" do
      result =
        query_gql(
          variables: %{
            "filesetIds" => ["", "valid-id", nil],
            "createWork" => false,
            "accessionNumber" => "SOME_WORK"
          },
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      # GraphQL validation happens first, so we get a different error
      assert String.contains?(error_message, "Expected type \"ID!\", found null") or
               String.contains?(error_message, "non-empty strings")
    end

    test "returns error when creating work without work_attributes" do
      fileset_ids = ["fake-id-1", "fake-id-2"]

      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => true
          },
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      # Our function should catch this and return a proper error
      assert String.contains?(error_message, "Work attributes are required")
    end

    test "returns error when transferring to existing work without accession_number" do
      fileset_ids = ["fake-id-1", "fake-id-2"]

      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => false
          },
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result
      assert String.contains?(error_message, "Accession number is required")
    end

    test "returns error for non-existent target work", %{fileset_ids: fileset_ids} do
      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => false,
            "accessionNumber" => "NON_EXISTENT_WORK"
          },
          context: gql_context()
        )

      assert {:ok, %{errors: [%{message: error_message}]}} = result

      assert String.contains?(error_message, "No work found") or
               String.contains?(error_message, "Work not found")
    end
  end

  describe "authorization" do
    test "viewers are not authorized to transfer file sets subset" do
      work1 = work_with_file_sets_fixture(2, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      fileset_ids = Enum.map(Enum.take(work1.file_sets, 1), & &1.id)

      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => true,
            "workAttributes" => %{
              "accessionNumber" => "TEST_WORK",
              "workType" => "IMAGE"
            }
          },
          context: %{current_user: %{role: :user}}
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end

    test "editors are authorized to transfer file sets subset" do
      work1 = work_with_file_sets_fixture(2, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      fileset_ids = Enum.map(Enum.take(work1.file_sets, 1), & &1.id)

      result =
        query_gql(
          variables: %{
            "filesetIds" => fileset_ids,
            "createWork" => true,
            "workAttributes" => %{
              "accessionNumber" => "TEST_WORK",
              "workType" => "IMAGE",
              "visibility" => %{"id" => "OPEN", "scheme" => "VISIBILITY"}
            }
          },
          context: %{current_user: %{role: :editor}}
        )

      assert {:ok, %{data: %{"transfer_file_sets_subset" => _}}} = result
    end
  end
end
