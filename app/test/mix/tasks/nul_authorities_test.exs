defmodule Mix.Tasks.Meadow.NulAuthoritiesTest do
  use Meadow.DataCase
  use Meadow.S3Case

  import ExUnit.CaptureLog

  alias NUL.AuthorityRecords

  @uploads_bucket Meadow.Config.upload_bucket()
  @filename "nul_authorities.csv"

  setup do
    upload_object(
      @uploads_bucket,
      "nul_authorities.csv",
      File.read!("test/fixtures/" <> @filename)
    )

    on_exit(fn ->
      delete_object(@uploads_bucket, @filename)
    end)
  end

  describe "nul_authorities.import/1 task" do
    test "import task" do
      log_output = capture_log(fn -> Mix.Task.run("nul_authorities.import", [@filename]) end)

      assert log_output =~
               "[info]  Looking for CSV in bucket: test-uploads, key: nul_authorities.csv"

      assert log_output =~ "[info]  Done"

      assert length(AuthorityRecords.list_authority_records()) == 14
    end
  end

  describe "nul_authorities.export task" do
    test "export task" do
      AuthorityRecords.create_authority_record!(%{label: "one"})
      AuthorityRecords.create_authority_record!(%{label: "two"})
      AuthorityRecords.create_authority_record!(%{label: "three"})

      log_output = capture_log(fn -> Mix.Task.run("nul_authorities.export", []) end)

      assert log_output =~
               "[info]  Done. Look for your export in bucket: test-uploads, key: nul_authorities_export.csv"

      assert(object_exists?(@uploads_bucket, "nul_authorities_export.csv"))

      on_exit(fn ->
        delete_object(@uploads_bucket, "nul_authorities_export.csv")
      end)
    end
  end
end
