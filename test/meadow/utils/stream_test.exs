defmodule Meadow.Utils.StreamTest do
  use Meadow.S3Case
  alias Meadow.Utils.Stream

  @bucket "test-ingest"
  @key "stream_test/path/to/test.tif"
  @content_length 1181
  @content Faker.Lorem.characters(@content_length)
  @fixture %{bucket: @bucket, key: @key, content: @content}

  setup do
    with {:ok, url} <- ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, @bucket, @key) do
      {:ok, url: url}
    end
  end

  describe "stream_from/1" do
    @tag s3: [@fixture]
    test "http", %{url: url} do
      assert Stream.stream_from(url)
             |> Enum.map(&byte_size/1)
             |> Enum.sum() == @content_length
    end

    @tag s3: [@fixture]
    test "s3" do
      assert Stream.stream_from("s3://#{@bucket}/#{@key}")
             |> Enum.map(&byte_size/1)
             |> Enum.sum() == @content_length
    end
  end

  describe "by_line/1" do
    assert [
             "this\nis lines\none through three\r\nand ",
             "this is\nlines four and five\n",
             "\r\n\n\r\n",
             "and this is line six\r\n"
           ]
           |> Stream.by_line()
           |> Enum.to_list() == [
             "this\n",
             "is lines\n",
             "one through three\r\n",
             "and this is\n",
             "lines four and five\n",
             "\r\n",
             "\n",
             "\r\n",
             "and this is line six\r\n"
           ]
  end
end
