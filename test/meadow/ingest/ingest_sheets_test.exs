defmodule Meadow.Ingest.IngestSheetsTest do
  use Meadow.DataCase

  alias Meadow.Ingest.IngestSheets
  alias Meadow.Ingest.IngestSheets.IngestSheet

  describe "ingest_sheets" do
    @valid_attrs %{
      name: "some name",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @update_attrs %{
      name: "some updated name",
      filename: "some_name.csv",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N"
    }
    @invalid_attrs %{name: nil, filename: nil}

    test "list_ingest_sheets/0 returns all ingest_sheets" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert IngestSheets.list_ingest_sheets(project) == [ingest_sheet]
    end

    test "get_ingest_sheet!/1 returns the sheet with given id" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert IngestSheets.get_ingest_sheet!(ingest_sheet.id) == ingest_sheet
    end

    test "create_ingest_sheet/1 with valid data creates a sheet" do
      project = project_fixture()

      assert {:ok, %IngestSheet{} = ingest_sheet} =
               IngestSheets.create_ingest_sheet(Map.put(@valid_attrs, :project_id, project.id))

      assert ingest_sheet.name == "some name"
    end

    test "create_ingest_sheet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = IngestSheets.create_ingest_sheet(@invalid_attrs)
    end

    test "update_ingest_sheet/2 with valid data updates the ingest sheet" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:ok, %IngestSheet{} = ingest_sheet} =
               IngestSheets.update_ingest_sheet(
                 ingest_sheet,
                 Map.put(@update_attrs, :project_id, project.id)
               )

      assert ingest_sheet.name == "some updated name"
    end

    test "update_ingest_sheet/2 with invalid data returns error changeset" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))

      assert {:error, %Ecto.Changeset{}} =
               IngestSheets.update_ingest_sheet(
                 ingest_sheet,
                 Map.put(@invalid_attrs, :project_id, project.id)
               )

      assert ingest_sheet == IngestSheets.get_ingest_sheet!(ingest_sheet.id)
    end

    test "delete_ingest_sheet/1 deletes the sheet" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert {:ok, %IngestSheet{}} = IngestSheets.delete_ingest_sheet(ingest_sheet)

      assert_raise Ecto.NoResultsError, fn ->
        IngestSheets.get_ingest_sheet!(ingest_sheet.id)
      end
    end

    test "change_sheet/1 returns a sheet changeset" do
      project = project_fixture()
      ingest_sheet = ingest_sheet_fixture(Map.put(@valid_attrs, :project_id, project.id))
      assert %Ecto.Changeset{} = IngestSheets.change_ingest_sheet(ingest_sheet)
    end
  end
end
