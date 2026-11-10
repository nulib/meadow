defmodule Meadow.Embeddings.ImageInputTest do
  use ExUnit.Case, async: true

  alias Meadow.Embeddings.ImageInput

  doctest Meadow.Embeddings.ImageInput

  @fixtures Path.expand("../../../../embedding-fixtures", __DIR__)

  defp fixture(name), do: File.read!(Path.join(@fixtures, name))

  describe "target_size/3" do
    test "keeps both sides a multiple of 48 and within the patch budget" do
      for {height, width} <- [{1024, 1024}, {1000, 837}, {3015, 3000}, {600, 4000}, {4000, 600}],
          budget <- [70, 140, 280, 560, 1120] do
        {target_height, target_width} = ImageInput.target_size(height, width, budget)

        assert rem(target_height, 48) == 0
        assert rem(target_width, 48) == 0
        assert div(target_height, 16) * div(target_width, 16) <= ImageInput.max_patches(budget)
      end
    end

    test "matches the model's own processor for the fixture images" do
      assert ImageInput.target_size(1024, 1024, 280) == {768, 768}
      assert ImageInput.target_size(1000, 837, 280) == {864, 720}
      assert ImageInput.target_size(3015, 3000, 280) == {768, 768}
    end

    test "scales small images up to the budget" do
      assert ImageInput.target_size(100, 100, 280) == {768, 768}
    end

    test "gives very elongated images one row or column of tokens" do
      assert ImageInput.target_size(10, 10_000, 280) == {48, 13_440}
      assert ImageInput.target_size(10_000, 10, 280) == {13_440, 48}
    end

    test "a smaller budget means a smaller image" do
      assert ImageInput.target_size(1024, 1024, 70) == {384, 384}
    end
  end

  describe "parity with the model's reference processor" do
    # Hashes of the 8-bit patch pixels transformers.js produces for the same
    # files (see test/fixtures/embeddings/transformers_js_reference.json)
    @reference "test/fixtures/embeddings/transformers_js_reference.json"
               |> File.read!()
               |> Jason.decode!()

    for {file, %{"pixels_sha256" => expected}} <- @reference do
      test "#{file} gives exactly the same pixels" do
        {:ok, input} = ImageInput.prepare(fixture(unquote(file)), 280)
        patches = input.soft_tokens * 9

        pixels =
          input.pixel_values[[0, 0..(patches - 1)]]
          |> Nx.multiply(255)
          |> Nx.round()
          |> Nx.as_type(:u8)
          |> Nx.to_binary()

        assert :crypto.hash(:sha256, pixels) |> Base.encode16(case: :lower) == unquote(expected)
      end
    end
  end

  describe "prepare/2" do
    test "cuts a square RGB TIFF into patches" do
      assert {:ok, %ImageInput{} = input} = ImageInput.prepare(fixture("coffee.tif"), 280)

      assert {input.height, input.width} == {768, 768}
      assert input.soft_tokens == 256
      assert Nx.shape(input.pixel_values) == {1, 2520, 768}
      assert Nx.type(input.pixel_values) == {:f, 32}
      assert Nx.shape(input.position_ids) == {1, 2520, 2}
      assert Nx.type(input.position_ids) == {:s, 64}
    end

    test "scales pixel values to 0..1 and zero-fills the padding patches" do
      {:ok, input} = ImageInput.prepare(fixture("coffee.tif"), 280)
      patches = 48 * 48

      real = input.pixel_values[[0, 0..(patches - 1)]]
      assert Nx.to_number(Nx.reduce_min(real)) >= 0.0
      assert Nx.to_number(Nx.reduce_max(real)) <= 1.0
      assert Nx.to_number(Nx.mean(real)) > 0.1
      assert Nx.to_number(Nx.sum(input.pixel_values[[0, patches..-1//1]])) == 0.0
    end

    test "numbers patches by column and row, and marks padding with -1" do
      {:ok, input} = ImageInput.prepare(fixture("coffee.tif"), 280)
      positions = Nx.to_list(input.position_ids[0])

      assert Enum.take(positions, 3) == [[0, 0], [1, 0], [2, 0]]
      assert Enum.at(positions, 48) == [0, 1]
      assert Enum.at(positions, 48 * 48 - 1) == [47, 47]
      assert Enum.at(positions, 48 * 48) == [-1, -1]
      assert List.last(positions) == [-1, -1]
    end

    test "keeps patch pixels in row-major, channel-last order" do
      # 96x48: left half red, right half blue
      {:ok, red} = Image.new(48, 48, color: [255, 0, 0])
      {:ok, blue} = Image.new(48, 48, color: [0, 0, 255])
      {:ok, image} = Image.join([red, blue], across: 2)
      {:ok, png} = Image.write(image, :memory, suffix: ".png")

      # A budget of 2 soft tokens (18 patches) leaves the 96x48 image as it is
      assert {:ok, input} = ImageInput.prepare(png, 2)
      assert {input.height, input.width, input.soft_tokens} == {48, 96, 2}

      first = Nx.to_list(input.pixel_values[[0, 0, 0..2]])
      last_in_row = Nx.to_list(input.pixel_values[[0, 5, 0..2]])
      assert first == [1.0, 0.0, 0.0]
      assert last_in_row == [0.0, 0.0, 1.0]
    end

    test "handles a portrait image with an alpha channel" do
      assert {:ok, input} = ImageInput.prepare(fixture("douglass_letter.tif"), 280)
      assert {input.height, input.width} == {864, 720}
      assert input.soft_tokens == 270
      assert Nx.shape(input.pixel_values) == {1, 2520, 768}
    end

    test "downsizes a large JPEG" do
      assert {:ok, input} = ImageInput.prepare(fixture("BFMF_B38_F10_025_002a.jpeg"), 280)
      assert {input.height, input.width} == {768, 768}
      assert input.soft_tokens == 256
    end

    test "honors a smaller soft token budget" do
      assert {:ok, input} = ImageInput.prepare(fixture("coffee.tif"), 70)
      assert {input.height, input.width} == {384, 384}
      assert input.soft_tokens == 64
      assert Nx.shape(input.pixel_values) == {1, 630, 768}
    end

    test "returns an error for something that is not an image" do
      assert {:error, _} = ImageInput.prepare("definitely not an image", 280)
    end
  end
end
