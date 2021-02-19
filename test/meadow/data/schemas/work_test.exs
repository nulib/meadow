defmodule Meadow.Data.Schemas.WorkTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work

  describe "works" do
    setup do
      {:ok,
       %{
         attrs: %{
           accession_number: "12345",
           descriptive_metadata: %{title: "Test"}
         }
       }}
    end

    test "created work has a UUID identifier", %{attrs: attrs} do
      {:ok, work} =
        %Work{}
        |> Work.changeset(attrs)
        |> Repo.insert()

      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(work.id)
    end
  end

  describe "migration_changeset/2" do
    @describetag authority_file: "test/fixtures/migration/terms.json"
    setup do
      attrs =
        File.read!("test/fixtures/migration/manifests/3a618a95-fa7e-4bec-b9c1-ac781b64cc56.json")
        |> Jason.decode!(keys: :atoms)
        |> Map.delete(:collection_id)
        |> Map.delete(:representative_file_set_id)

      %{id: work_id, file_sets: [%{id: file_set_id} | []]} = attrs

      {:ok, %{work_id: work_id, file_set_id: file_set_id, attrs: attrs}}
    end

    test "created work and file set retain original ID", %{
      attrs: attrs,
      work_id: work_id,
      file_set_id: file_set_id
    } do
      {:ok, work} =
        Work.migration_changeset(attrs)
        |> Repo.insert()

      assert %{id: ^work_id, file_sets: [%{id: ^file_set_id} | []]} = work
    end
  end
end
