defmodule Meadow.AWS.S3Test do
  use Meadow.S3Case

  @upload_id "example-upload-id"
  @key "s3_test/source.txt"
  @fixture %{bucket: @ingest_bucket, key: @key, content: "s3 test content"}

  describe "list_buckets/0" do
    test "returns bucket names" do
      assert {:ok, buckets} = S3.list_buckets()
      assert @ingest_bucket in buckets
    end
  end

  describe "copy_object/5" do
    @describetag s3: [@fixture]

    setup do
      on_exit(fn -> delete_object(@ingest_bucket, "s3_test/copy.txt") end)
    end

    test "returns the new object's etag" do
      assert {:ok, %{etag: etag}} =
               S3.copy_object(@ingest_bucket, "s3_test/copy.txt", @ingest_bucket, @key)

      assert {:ok, %{etag: ^etag}} = S3.head_object(@ingest_bucket, "s3_test/copy.txt")
    end
  end

  describe "create_multipart_upload/3" do
    test "sends CopyObject directives as nothing at all, and metadata and tags as headers" do
      test_pid = self()

      Req.Test.stub(__MODULE__, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(test_pid, {:request, conn, body})

        Plug.Conn.send_resp(conn, 200, """
        <?xml version="1.0" encoding="UTF-8"?>
        <InitiateMultipartUploadResult>
          <Bucket>bucket</Bucket>
          <Key>path/to/key</Key>
          <UploadId>#{@upload_id}</UploadId>
        </InitiateMultipartUploadResult>
        """)
      end)

      assert {:ok, @upload_id} =
               S3.create_multipart_upload("bucket", "path/to/key",
                 content_type: "image/tiff",
                 metadata_directive: "REPLACE",
                 meta: [md5: "abc123"],
                 tagging: "computed-md5=abc123",
                 tagging_directive: "REPLACE",
                 plug: {Req.Test, __MODULE__}
               )

      assert_received {:request, conn, body}
      assert conn.method == "POST"
      assert conn.request_path == "/bucket/path/to/key"
      assert conn.query_string == "uploads"
      # S3 rejects a CreateMultipartUpload request that carries a body
      assert body == ""
      assert Plug.Conn.get_req_header(conn, "content-type") == ["image/tiff"]
      assert Plug.Conn.get_req_header(conn, "x-amz-meta-md5") == ["abc123"]
      assert Plug.Conn.get_req_header(conn, "x-amz-tagging") == ["computed-md5=abc123"]
    end
  end
end
