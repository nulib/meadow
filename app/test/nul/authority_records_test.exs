defmodule NUL.AuthorityRecordsTest do
  use Meadow.DataCase

  alias NUL.AuthorityRecords
  alias NUL.Schemas.AuthorityRecord

  setup do
    authority_records = [
      authority_record_fixture(%{label: "Ver Steeg, Clarence L.", hint: "(The Legend)"}),
      authority_record_fixture(%{label: "Ver Steeg, Dorothy A."}),
      authority_record_fixture(%{label: "Netsch, Walter A."})
    ]

    {:ok, authority_record: List.first(authority_records)}
  end

  def authority_record_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        label: attrs[:label] || Faker.Person.name(),
        hint: attrs[:hint] || Faker.Lorem.sentence(2)
      })

    {:ok, authority_record} =
      %AuthorityRecord{}
      |> AuthorityRecord.changeset(attrs)
      |> Repo.insert()

    authority_record
  end

  test "list_authority_records/0" do
    assert AuthorityRecords.list_authority_records() |> length() == 3
  end

  test "get_authority_record!/1", %{authority_record: authority_record} do
    assert AuthorityRecords.get_authority_record!(authority_record.id)
    assert_raise Ecto.NoResultsError, fn -> AuthorityRecords.get_authority_record!("M1SS1NG") end
  end

  test "get_authority_record/1", %{authority_record: authority_record} do
    assert AuthorityRecords.get_authority_record(authority_record.id)
    assert is_nil(AuthorityRecords.get_authority_record("M1SS1NG"))
  end

  test "create_authority_record/1" do
    assert {:ok, _authority_record} =
             AuthorityRecords.create_authority_record(%{
               label: "test label",
               hint: "test hint"
             })

    assert {:error, %Ecto.Changeset{}} =
             AuthorityRecords.create_authority_record(%{hint: "test hint"})
  end

  test "create_authority_record!/1" do
    assert %NUL.Schemas.AuthorityRecord{} =
             AuthorityRecords.create_authority_record!(%{
               label: "test label",
               hint: "test hint"
             })

    assert_raise Ecto.InvalidChangesetError, fn ->
      AuthorityRecords.create_authority_record!(%{hint: "test hint"})
    end
  end

  test "create_authority_record!/1 labels are unique" do
    AuthorityRecords.create_authority_record!(%{
      label: "test label",
      hint: "test hint"
    })

    assert_raise Ecto.InvalidChangesetError, fn ->
      AuthorityRecords.create_authority_record!(%{
        label: "test label",
        hint: "test hint"
      })
    end
  end

  test "update_authority_record/2", %{authority_record: authority_record} do
    assert {:ok, %NUL.Schemas.AuthorityRecord{label: "new label"}} =
             AuthorityRecords.update_authority_record(authority_record, %{label: "new label"})
  end

  test "delete_authority_record/1", %{authority_record: authority_record} do
    assert {:ok, _authority_record} = AuthorityRecords.delete_authority_record(authority_record)
  end

  test "with_stream/0" do
    assert {:ok, 3} = AuthorityRecords.with_stream(fn stream ->
      stream
      |> Stream.map(&(&1))
      |> Enum.to_list()
      |> length()
    end)
  end
end
