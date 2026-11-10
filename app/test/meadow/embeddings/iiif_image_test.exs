defmodule Meadow.Embeddings.IIIFImageTest do
  use Meadow.DataCase

  alias Meadow.Embeddings.IIIFImage

  doctest Meadow.Embeddings.IIIFImage

  setup do
    config = Application.get_env(:meadow, Meadow.Embeddings)

    Application.put_env(
      :meadow,
      Meadow.Embeddings,
      Keyword.put(config, :req_options, plug: {Req.Test, __MODULE__}, retry: false)
    )

    on_exit(fn -> Application.put_env(:meadow, Meadow.Embeddings, config) end)

    file_set =
      file_set_fixture(%{
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        derivatives: %{"pyramid_tiff" => "s3://pyramids/image.tif"}
      })

    {:ok, file_set: file_set}
  end

  defp stub_iiif(test_pid, info, image_response) do
    Req.Test.stub(__MODULE__, fn conn ->
      send(
        test_pid,
        {:iiif_request, conn.request_path, Plug.Conn.get_req_header(conn, "authorization")}
      )

      if String.ends_with?(conn.request_path, "/info.json"),
        do: Req.Test.json(conn, info),
        else: image_response.(conn)
    end)
  end

  describe "variant/2" do
    test "asks for the model's target size" do
      assert IIIFImage.variant(1000, 837) == "full/720,864/0/default.png"
    end

    test "asks for the whole image when it is smaller than the target" do
      assert IIIFImage.variant(300, 400) == "full/max/0/default.png"
      assert IIIFImage.variant(700, 2000) == "full/1344,432/0/default.png"
    end
  end

  describe "fetch/1" do
    test "reads the dimensions, then requests the image at the target size", %{file_set: file_set} do
      stub_iiif(self(), %{"width" => 3000, "height" => 3015}, fn conn ->
        Plug.Conn.send_resp(conn, 200, "png bytes")
      end)

      assert IIIFImage.fetch(file_set) == {:ok, "png bytes"}

      assert_received {:iiif_request, info_path, ["Bearer " <> _]}
      assert String.ends_with?(info_path, "#{file_set.id}/info.json")
      assert_received {:iiif_request, image_path, ["Bearer " <> _]}
      assert String.ends_with?(image_path, "#{file_set.id}/full/768,768/0/default.png")
    end

    test "returns the status when the image request fails", %{file_set: file_set} do
      stub_iiif(self(), %{"width" => 3000, "height" => 3015}, fn conn ->
        Plug.Conn.send_resp(conn, 502, "bad gateway")
      end)

      assert IIIFImage.fetch(file_set) == {:error, {:http_error, 502, "bad gateway"}}
    end

    test "returns the status when the image is not there yet", %{file_set: file_set} do
      Req.Test.stub(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 404, "not found") end)
      assert {:error, {:http_error, 404, _}} = IIIFImage.fetch(file_set)
    end

    test "returns an error when the info document is unusable", %{file_set: file_set} do
      stub_iiif(self(), %{"error" => "nope"}, fn _conn -> flunk("unexpected request") end)
      assert IIIFImage.fetch(file_set) == {:error, :invalid_image_info}
    end

    test "has nothing to fetch for a file set without an IIIF image" do
      file_set = file_set_fixture(%{derivatives: %{}})
      Req.Test.stub(__MODULE__, fn _conn -> flunk("unexpected request") end)
      assert IIIFImage.fetch(file_set) == {:error, :no_image}
    end
  end
end
