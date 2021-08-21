defmodule Meadow.Ingest.SheetsTest do
  use Meadow.DataCase

  alias Meadow.Data.Works
  alias Meadow.Ingest.Schemas.Sheet
  alias Meadow.Ingest.{Progress, Rows, Sheets}

  describe "ingest_sheets" do
    @valid_attrs %{
      title: "some title",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @update_attrs %{
      title: "some updated title",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @invalid_attrs %{title: nil, filename: nil}

    test "list_ingest_sheets/0 returns all ingest_sheets" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Sheets.list_ingest_sheets(project) == [ingest_sheet]
    end

    test "get_ingest_sheet!/1 returns the sheet with given id" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Sheets.get_ingest_sheet!(ingest_sheet.id) == ingest_sheet
    end

    test "get_ingest_sheet_by_title/1 returns the sheet with given title" do
      assert is_nil(Sheets.get_ingest_sheet_by_title(@valid_attrs.title))
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Sheets.get_ingest_sheet_by_title(@valid_attrs.title) == ingest_sheet
    end

    test "create_ingest_sheet/1 with valid data creates a sheet" do
      project = project_fixture()

      assert {:ok, %Sheet{} = ingest_sheet} =
               Sheets.create_ingest_sheet(Map.put(@valid_attrs, :project_id, project.id))

      assert ingest_sheet.title == "some title"
    end

    test "create_ingest_sheet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sheets.create_ingest_sheet(@invalid_attrs)
    end

    test "update_ingest_sheet/2 with valid data updates the ingest sheet" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:ok, %Sheet{} = ingest_sheet} =
               Sheets.update_ingest_sheet(
                 ingest_sheet,
                 Map.put(@update_attrs, :project_id, project.id)
               )

      assert ingest_sheet.title == "some updated title"
    end

    test "update_ingest_sheet/2 with invalid data returns error changeset" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:error, %Ecto.Changeset{}} =
               Sheets.update_ingest_sheet(
                 ingest_sheet,
                 Map.put(@invalid_attrs, :project_id, project.id)
               )

      assert ingest_sheet == Sheets.get_ingest_sheet!(ingest_sheet.id)
    end

    test "delete_ingest_sheet/1 deletes the sheet" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert {:ok, %Sheet{}} = Sheets.delete_ingest_sheet(ingest_sheet)

      assert_raise Ecto.NoResultsError, fn ->
        Sheets.get_ingest_sheet!(ingest_sheet.id)
      end
    end

    test "deleting an ingest sheet retains its works" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      work = work_fixture(%{ingest_sheet_id: ingest_sheet.id})

      with test_work <- Works.get_work!(work.id) do
        assert test_work.ingest_sheet_id == ingest_sheet.id
      end

      assert {:ok, %Sheet{}} = Sheets.delete_ingest_sheet(ingest_sheet)

      with test_work <- Works.get_work!(work.id) do
        assert is_nil(test_work.ingest_sheet_id)
      end
    end

    test "change_sheet/1 returns a sheet changeset" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert %Ecto.Changeset{} = Sheets.change_ingest_sheet(ingest_sheet)
    end

    test "list_ingest_sheets_by_status/1" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Sheets.list_ingest_sheets_by_status(ingest_sheet.status) == [ingest_sheet]
      assert Sheets.list_ingest_sheets_by_status(:completed) == []
    end

    test "list_recently_updated/1" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert Sheets.list_recently_updated(60) == [ingest_sheet]

      Sheets.update_ingest_sheet(ingest_sheet, %{
        updated_at: DateTime.add(DateTime.utc_now(), -120, :second)
      })

      assert Sheets.list_recently_updated(60) == []
    end

    test "list_ingest_sheet_works/2" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))

      1..30
      |> Enum.each(fn _ -> work_fixture(%{ingest_sheet_id: ingest_sheet.id}) end)

      assert Sheets.list_ingest_sheet_works(ingest_sheet) |> length() == 30
      assert Sheets.list_ingest_sheet_works(ingest_sheet, 2) |> length() == 2
      assert Sheets.list_ingest_sheet_works(ingest_sheet, 50) |> length() == 30
    end

    test "work_count/1" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))

      1..30
      |> Enum.each(fn _ -> work_fixture(%{ingest_sheet_id: ingest_sheet.id}) end)

      assert Sheets.work_count(ingest_sheet) == 30
    end
  end

  describe "update_completed_sheets/0" do
    @fixture "test/fixtures/ingest_sheet.csv"

    setup tags do
      {:ok, ingest_sheet} =
        ingest_sheet_rows_fixture(@fixture) |> Sheets.update_ingest_sheet_status("approved")

      with rows <- Rows.list_ingest_sheet_rows(sheet: ingest_sheet) do
        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, index} ->
          {row.id, rem(index, 4) == 0}
        end)
        |> Progress.initialize_entries()

        Progress.get_entries(ingest_sheet)
        |> Enum.each(&Progress.update_entry(&1.row_id, &1.action, Enum.random(tags[:statuses])))

        {:ok, %{ingest_sheet: ingest_sheet}}
      end
    end

    @tag statuses: ["ok", "error"]
    test "sets status to completed_error when there are errors", %{ingest_sheet: ingest_sheet} do
      Sheets.update_completed_sheets()
      assert Sheets.get_ingest_sheet!(ingest_sheet.id).status == "completed_error"
    end

    @tag statuses: ["ok"]
    test "sets status to completed on when all ok", %{ingest_sheet: ingest_sheet} do
      Sheets.update_completed_sheets()
      assert Sheets.get_ingest_sheet!(ingest_sheet.id).status == "completed"
    end

    @tag statuses: ["ok", "pending"]
    test "doesn't change status when not complete", %{ingest_sheet: ingest_sheet} do
      Sheets.update_completed_sheets()

      with sheet <- assert(Sheets.get_ingest_sheet!(ingest_sheet.id)) do
        assert sheet.status == "approved"
        assert sheet.updated_at == ingest_sheet.updated_at
      end
    end
  end
end
