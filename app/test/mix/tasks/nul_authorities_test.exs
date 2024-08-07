defmodule Mix.Tasks.Meadow.NulAuthoritiesTest do
  use Meadow.DataCase
  use Meadow.S3Case

  import ExUnit.CaptureLog

  alias NUL.AuthorityRecords

  @filename "nul_authorities.csv"

  setup do
    upload_object(
      @upload_bucket,
      "nul_authorities.csv",
      File.read!("test/fixtures/" <> @filename)
    )

    on_exit(fn ->
      delete_object(@upload_bucket, @filename)
    end)
  end

  describe "nul_authorities.import/1 task" do
    test "import task" do
      log_output = capture_log(fn -> Mix.Task.run("nul_authorities.import", [@filename]) end)

      assert log_output
             |> logged?(
               :info,
               "Looking for CSV in bucket: #{@upload_bucket}, key: nul_authorities.csv"
             )

      assert log_output |> logged?(:info, "Done")

      assert length(AuthorityRecords.list_authority_records()) == 14
    end
  end

  describe "nul_authorities.export task" do
    test "export task" do
      AuthorityRecords.create_authority_record!(%{label: "one"})
      AuthorityRecords.create_authority_record!(%{label: "two"})
      AuthorityRecords.create_authority_record!(%{label: "three"})

      log_output = capture_log(fn -> Mix.Task.run("nul_authorities.export", []) end)

      assert log_output
             |> logged?(
               :info,
               "Done. Look for your export in bucket: #{@upload_bucket}, key: nul_authorities_export.csv"
             )

      assert(object_exists?(@upload_bucket, "nul_authorities_export.csv"))

      on_exit(fn ->
        delete_object(@upload_bucket, "nul_authorities_export.csv")
      end)
    end
  end
end
