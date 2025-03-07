defmodule MeadowWeb.Schema.Mutation.TransferFileSetsTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, acync: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/TransferFileSets.gql")

  describe "mutation" do
    setup do
      work1 = work_with_file_sets_fixture(3)
      work2 = work_with_file_sets_fixture(3)
      {:ok, %{work1: work1, work2: work2}}
    end

    test "transfers file sets from one work to another", %{work1: work1, work2: work2} do
      result =
        query_gql(
          variables: %{"fromWorkId" => work1.id, "toWorkId" => work2.id},
          context: gql_context()
        )

      assert {:ok, _query_data} = result
    end

    # test "missing IDs", %{work: work, ids: ids} do
    #   result =
    #     query_gql(
    #       variables: %{"workId" => work.id, "fileSetIds" => Enum.slice(ids, 0..2)},
    #       context: gql_context()
    #     )

    #   assert {:ok, %{errors: [%{details: %{error: error_text}}]}} = result

    #   Enum.slice(ids, 3..4)
    #   |> Enum.each(fn id ->
    #     assert String.contains?(error_text, id)
    #   end)

    #   assert String.match?(error_text, ~r/missing \[.+\]/)
    # end

    # test "extra IDs", %{work: work, ids: ids} do
    #   extra_ids = [Ecto.UUID.generate(), Ecto.UUID.generate()]

    #   result =
    #     query_gql(
    #       variables: %{"workId" => work.id, "fileSetIds" => (ids ++ extra_ids) |> Enum.shuffle()},
    #       context: gql_context()
    #     )

    #   assert {:ok, %{errors: [%{details: %{error: error_text}}]}} = result

    #   Enum.each(extra_ids, fn id ->
    #     assert String.contains?(error_text, id)
    #   end)

    #   assert String.match?(error_text, ~r/^Extra/)
    # end
  end

  describe "authorization" do
    test "viewers are not authoried to update file set order" do
      work = work_with_file_sets_fixture(1)
      work2 = work_with_file_sets_fixture(1)

      result =
        query_gql(
          variables: %{"fromWorkId" => work.id, "toWorkId" => work2.id},
          context: %{current_user: %{role: "User"}}
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end
  end
end
