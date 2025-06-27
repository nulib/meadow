defmodule MeadowWeb.Schema.Mutation.UpdateAccessFileOrderTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, acync: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/UpdateAccessFileOrder.gql")

  describe "mutation" do
    setup do
      work = work_with_file_sets_fixture(5, %{}, %{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      {:ok, %{work: work, ids: work.file_sets |> Enum.map(& &1.id)}}
    end

    test "changes the access file order", %{work: work, ids: ids} do
      new_order = Enum.shuffle(ids)

      result =
        query_gql(
          variables: %{"workId" => work.id, "fileSetIds" => new_order},
          context: gql_context()
        )

      assert {:ok, query_data} = result

      with %{"id" => returned_work_id, "fileSets" => returned_file_sets} <-
             get_in(query_data, [:data, "updateAccessFileOrder"]) do
        assert returned_work_id == work.id
        assert returned_file_sets |> Enum.map(&Map.get(&1, "id")) == new_order
      end
    end

    test "missing IDs", %{work: work, ids: ids} do
      result =
        query_gql(
          variables: %{"workId" => work.id, "fileSetIds" => Enum.slice(ids, 0..2)},
          context: gql_context()
        )

      assert {:ok, %{errors: [%{details: %{error: error_text}}]}} = result

      Enum.slice(ids, 3..4)
      |> Enum.each(fn id ->
        assert String.contains?(error_text, id)
      end)

      assert String.match?(error_text, ~r/missing \[.+\]/)
    end

    test "extra IDs", %{work: work, ids: ids} do
      extra_ids = [Ecto.UUID.generate(), Ecto.UUID.generate()]

      result =
        query_gql(
          variables: %{"workId" => work.id, "fileSetIds" => (ids ++ extra_ids) |> Enum.shuffle()},
          context: gql_context()
        )

      assert {:ok, %{errors: [%{details: %{error: error_text}}]}} = result

      Enum.each(extra_ids, fn id ->
        assert String.contains?(error_text, id)
      end)

      assert String.match?(error_text, ~r/^Extra/)
    end
  end

  describe "authorization" do
    test "viewers are not authoried to update file set order" do
      work = work_with_file_sets_fixture(5)
      file_set_ids = work.file_sets |> Enum.map(& &1.id)

      result =
        query_gql(
          variables: %{"workId" => work.id, "fileSetIds" => Enum.reverse(file_set_ids)},
          context: %{current_user: %{role: :user}}
        )

      assert {:ok, %{errors: [%{message: "Forbidden", status: 403}]}} = result
    end
  end
end
