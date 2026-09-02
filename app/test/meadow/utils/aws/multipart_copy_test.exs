defmodule Meadow.Utils.AWS.MultipartCopyTest do
  use Meadow.S3Case

  alias Meadow.Utils.AWS.MultipartCopy

  # Just over MultipartCopy's 20 MiB single-request threshold, copied in S3's
  # minimum 5 MiB parts so the copy takes several UploadPartCopy requests.
  @size 21 * 1024 * 1024
  @chunk_size 5 * 1024 * 1024
  @src_key "multipart_copy_test/source.bin"
  @dest_key "multipart_copy_test/destination.bin"
  @fixture %{
    bucket: @ingest_bucket,
    key: @src_key,
    content: :binary.copy(<<0>>, @size)
  }

  describe "copy_object/5 above the multipart threshold" do
    @describetag s3: [@fixture]

    setup do
      on_exit(fn -> delete_object(@preservation_bucket, @dest_key) end)
    end

    test "copies the object with the options CopyFileToPreservation passes" do
      assert {:ok, %{content_length: @size}} =
               MultipartCopy.copy_object(
                 @preservation_bucket,
                 @dest_key,
                 @ingest_bucket,
                 @src_key,
                 chunk_size: @chunk_size,
                 content_type: "application/octet-stream",
                 metadata_directive: "REPLACE",
                 meta: [sha256: "abc123"],
                 tagging: "computed-sha256=abc123",
                 tagging_directive: "REPLACE"
               )

      assert object_size(@preservation_bucket, @dest_key) == @size
      assert object_metadata(@preservation_bucket, @dest_key) == %{sha256: "abc123"}

      assert {:ok, [%{key: "computed-sha256", value: "abc123"}]} =
               S3.get_object_tagging(@preservation_bucket, @dest_key)
    end
  end
end
