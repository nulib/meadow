defmodule Meadow.Utils.SitemapTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Utils.Sitemap

  import ExUnit.CaptureLog

  @bucket "test-uploads"
  @expected_files ["sitemap.xml.gz", "sitemap-00001.xml.gz"]

  describe "generate/0" do
    setup do
      on_exit(fn ->
        @expected_files
        |> Enum.each(&delete_object(@bucket, &1))
      end)
    end

    test "generates and uploads sitemaps" do
      log =
        capture_log(fn ->
          Sitemap.generate()
        end)

      @expected_files
      |> Enum.each(fn file ->
        assert %{"size" => size} =
                 Regex.named_captures(
                   ~r"Uploading (?<size>\d+) bytes to s3://#{@bucket}/#{file}",
                   log
                 )

        assert object_exists?(@bucket, file)
        assert object_size(@bucket, file) == String.to_integer(size)
      end)
    end
  end
end
