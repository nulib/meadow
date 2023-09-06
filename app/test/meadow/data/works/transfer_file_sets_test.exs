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
      from_work = work_with_file_sets_fixture(1, %{work_type: %{id: "IMAGE", scheme: "work_type"}})
      from_work_id = from_work.id
      to_work = work_with_file_sets_fixture(1, %{work_type: %{id: "AUDIO", scheme: "work_type"}})
      to_work_id = to_work.id

      assert {:error, "Checking work types: work types do not match (no changes were made)"} = TransferFileSets.transfer(from_work_id, to_work_id)

      reloaded_from_work = Works.get_work!(from_work_id) |> Repo.preload(:file_sets)
      reloaded_to_work = Works.get_work!(to_work_id) |> Repo.preload(:file_sets)

      assert Enum.map(from_work.file_sets, & &1.id) ==
               Enum.map(reloaded_from_work.file_sets, & &1.id)

      assert Enum.map(to_work.file_sets, & &1.id) == Enum.map(reloaded_to_work.file_sets, & &1.id)
    end

    test "handles work retrieval errors for 'from' work", %{to_work_id: to_work_id} do
      from_work_id = Ecto.UUID.generate()
      assert {:error, "Fetching 'from' work: work not found (no changes were made)"} = TransferFileSets.transfer(from_work_id, to_work_id)
    end

    test "handles work retrieval errors for 'to' work", %{
      from_work_id: from_work_id,

    } do
      to_work_id = Ecto.UUID.generate()

      assert {:error, "Fetching 'to' work: work not found (no changes were made)"} = TransferFileSets.transfer(from_work_id, to_work_id)
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
