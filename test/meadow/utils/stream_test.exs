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
             "and this is line six\r\n",
             ""
           ]

    assert ["one\ntwo\nthree", "four\nfive"] |> Stream.by_line() |> Enum.to_list() == [
             "one\n",
             "two\n",
             "threefour\n",
             "five"
           ]
  end

  describe "list_contents/1" do
    test "file://" do
      with path <- Path.expand("test/fixtures/csv"),
           result <- Stream.list_contents("file://#{path}") do
        assert result |> length() > 0

        assert result
               |> Enum.all?(fn "file://" <> file ->
                 file |> File.regular?() and
                   file |> String.contains?("test/fixtures/csv")
               end)
      end
    end

    @tag s3: [@fixture]
    test "s3://" do
      with result <- Stream.list_contents("s3://#{@bucket}/stream_test") do
        assert result |> length() == 1
        assert result |> Enum.all?(&Stream.exists?/1)
      end
    end
  end

  describe "copy/2" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      on_exit(fn -> File.rm_rf(tmp_dir) end)
    end

    test "file to file", %{tmp_dir: tmp_dir} do
      with path <- Path.expand("test/fixtures/coffee.tif"),
           tmp_dir <- Path.expand(tmp_dir) do
        refute File.regular?("#{tmp_dir}/output.bin")
        Stream.copy("file://#{path}", "file://#{tmp_dir}/output.bin")
        assert File.regular?("#{tmp_dir}/output.bin")
      end
    end

    @tag s3: [@fixture]
    test "s3 to s3" do
      on_exit(fn ->
        delete_object("test-preservation", "path/to/new_key.bin")
      end)

      refute object_exists?("test-preservation", "path/to/new_key.bin")
      Stream.copy("s3://#{@bucket}/#{@key}", "s3://test-preservation/path/to/new_key.bin")
      assert object_exists?("test-preservation", "path/to/new_key.bin")
    end

    @tag s3: [@fixture]
    test "s3 to file", %{tmp_dir: tmp_dir} do
      with tmp_dir <- Path.expand(tmp_dir) do
        refute File.regular?("#{tmp_dir}/output.bin")
        Stream.copy("s3://#{@bucket}/#{@key}", "file://#{tmp_dir}/output.bin")
        assert File.regular?("#{tmp_dir}/output.bin")
      end
    end

    test "small file to s3" do
      on_exit(fn ->
        delete_object("test-preservation", "path/to/new_key.bin")
      end)

      with path <- Path.expand("test/fixtures/coffee.tif") do
        refute object_exists?("test-preservation", "path/to/new_key.bin")
        Stream.copy("file://#{path}", "s3://test-preservation/path/to/new_key.bin")
        assert object_exists?("test-preservation", "path/to/new_key.bin")
      end
    end

    test "big file to s3", %{tmp_dir: tmp_dir} do
      on_exit(fn ->
        delete_object("test-preservation", "path/to/new_key.bin")
      end)

      with tmp_dir <- Path.expand(tmp_dir),
           path <- Path.join([tmp_dir, "big_file.bin"]),
           file_size <- 6 * 1024 * 1024 do
        File.write!(path, Faker.random_bytes(file_size))
        refute object_exists?("test-preservation", "path/to/new_key.bin")
        Stream.copy("file://#{path}", "s3://test-preservation/path/to/new_key.bin")
        assert object_exists?("test-preservation", "path/to/new_key.bin")
        assert object_size("test-preservation", "path/to/new_key.bin") == file_size
      end
    end
  end
end
