defmodule Meadow.Utils.StreamTest do
  use Meadow.S3Case
  alias Meadow.Utils.Stream

  @bucket "test-bucket"
  @key "path/to/test.tif"
  @chunk_size 64
  @content_length 1181
  @chunks div(@content_length, @chunk_size)
  @leftover rem(@content_length, @chunk_size)
  @context [
    bucket: @bucket,
    key: @key,
    content: Faker.Lorem.characters(@content_length),
    chunk_size: @chunk_size
  ]

  describe "stream_from/1" do
    @tag @context
    test "http", %{port: port} do
      Stream.stream_from("http://localhost:#{port}/#{@bucket}/#{@key}")
      |> handle_stream()

      assert_received({0, @chunk_size})
      assert_received({1, @chunk_size})
      assert_received({2, @chunk_size})
      assert_received({3, @chunk_size})
      assert_received({@chunks, @leftover})
    end

    @tag @context
    test "stream_from/1" do
      Stream.stream_from("s3://#{@bucket}/#{@key}")
      |> handle_stream()

      assert_received({0, @chunk_size})
      assert_received({1, @chunk_size})
      assert_received({2, @chunk_size})
      assert_received({3, @chunk_size})
      assert_received({@chunks, @leftover})
    end
  end

  defp handle_stream(s) do
    s
    |> Elixir.Stream.with_index()
    |> Elixir.Stream.each(fn {chunk, index} ->
      send(self(), {index, byte_size(chunk)})
    end)
    |> Elixir.Stream.run()
  end
end
