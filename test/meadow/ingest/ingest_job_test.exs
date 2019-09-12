defmodule Meadow.Ingest.IngestJobTest do
  use Meadow.DataCase
  alias Meadow.Ingest.IngestJob
  doctest Meadow.Ingest.IngestJob

  describe "ingest_jobs" do
    @valid_attrs %{
      name: "some name",
      project_id: "01DFC45C20ZMBD1R57HWTSKJ1N",
      filename: "test.csv"
    }

    test "validates csv format" do
      attrs = %{@valid_attrs | filename: "test.jpg"}
      changeset = IngestJob.changeset(%IngestJob{}, attrs)
      assert %{filename: ["is not a csv"]} = errors_on(changeset)
    end
  end
end
