defmodule Meadow.Pipeline.Actions.EmbedImageTest do
  use Meadow.PipelineCase
  use Meadow.DataCase

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.FileSetEmbedding
  alias Meadow.Embeddings
  alias Meadow.Embeddings.Model.Stub
  alias Meadow.Pipeline.Actions.EmbedImage

  import ExUnit.CaptureLog

  @image File.read!(Path.expand("../../../../embedding-fixtures/coffee.tif", __DIR__))

  setup do
    config = Application.get_env(:meadow, Meadow.Embeddings)

    Application.put_env(
      :meadow,
      Meadow.Embeddings,
      Keyword.put(config, :req_options, plug: {Req.Test, __MODULE__}, retry: false)
    )

    on_exit(fn -> Application.put_env(:meadow, Meadow.Embeddings, config) end)
    start_supervised!(Stub)

    file_set =
      file_set_fixture(%{
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://ingest/coffee.tif",
          original_filename: "coffee.tif",
          mime_type: "image/tiff"
        },
        derivatives: %{"pyramid_tiff" => "s3://pyramids/coffee.tif"}
      })

    {:ok, file_set_id: file_set.id}
  end

  defp stub_iiif(image_status \\ 200) do
    test_pid = self()

    Req.Test.stub(__MODULE__, fn conn ->
      send(test_pid, {:iiif_request, conn.request_path})

      cond do
        String.ends_with?(conn.request_path, "/info.json") ->
          Req.Test.json(conn, %{"width" => 1024, "height" => 1024})

        image_status == 200 ->
          Plug.Conn.send_resp(conn, 200, @image)

        true ->
          Plug.Conn.send_resp(conn, image_status, "failed")
      end
    end)
  end

  describe "already_complete?/2" do
    test "is true only with an embedding from the current model", %{file_set_id: file_set_id} do
      file_set = Meadow.Data.FileSets.get_file_set!(file_set_id)
      refute EmbedImage.already_complete?(file_set, %{})

      {:ok, _} = Embeddings.embed_file_set(file_set, @image)
      assert EmbedImage.already_complete?(file_set, %{})

      Repo.update_all(FileSetEmbedding, set: [model: "some-other-model"])
      refute EmbedImage.already_complete?(file_set, %{})
    end

    test "marks the action complete instead of overwriting", %{file_set_id: file_set_id} do
      file_set = Meadow.Data.FileSets.get_file_set!(file_set_id)
      {:ok, _} = Embeddings.embed_file_set(file_set, @image)
      Req.Test.stub(__MODULE__, fn _conn -> flunk("unexpected request") end)

      capture_log(fn ->
        send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{overwrite: "false"})
      end)

      assert ActionStates.ok?(file_set_id, EmbedImage)
      assert length(Stub.prompts()) == 1
    end
  end

  describe "process/2" do
    test "embeds the IIIF image and stores the vector", %{file_set_id: file_set_id} do
      stub_iiif()

      assert {:ok, %{id: ^file_set_id}, %{}} =
               send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})

      assert ActionStates.ok?(file_set_id, EmbedImage)
      assert_received {:iiif_request, info_path}
      assert String.ends_with?(info_path, "#{file_set_id}/info.json")
      assert_received {:iiif_request, image_path}
      assert String.ends_with?(image_path, "#{file_set_id}/full/768,768/0/default.png")

      assert %FileSetEmbedding{} = embedding = Embeddings.get_file_set_embedding(file_set_id)
      assert embedding.model == "embeddinggemma-2"
      assert embedding.soft_tokens == 280
      assert FileSetEmbedding.to_list(embedding) == Stub.vector(@image)
    end

    test "is skipped once the file set has an embedding", %{file_set_id: file_set_id} do
      stub_iiif()
      send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})

      assert capture_log(fn ->
               send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})
             end) =~ "Skipping #{EmbedImage} for #{file_set_id} - already complete"

      assert length(Stub.prompts()) == 1
    end

    test "embeds again when forced", %{file_set_id: file_set_id} do
      stub_iiif()
      send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})

      capture_log(fn ->
        assert {:ok, _, _} =
                 send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{force: "true"})
      end)

      assert length(Stub.prompts()) == 2
      assert Repo.aggregate(FileSetEmbedding, :count) == 1
    end

    test "succeeds without embedding when embeddings are disabled", %{file_set_id: file_set_id} do
      config = Application.get_env(:meadow, Meadow.Embeddings)
      Application.put_env(:meadow, Meadow.Embeddings, Keyword.put(config, :enabled, false))
      Req.Test.stub(__MODULE__, fn _conn -> flunk("unexpected request") end)

      assert {:ok, _, _} = send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})
      assert ActionStates.ok?(file_set_id, EmbedImage)
      refute Embeddings.get_file_set_embedding(file_set_id)
      assert Stub.prompts() == []
    end

    test "retries when the IIIF server is not ready", %{file_set_id: file_set_id} do
      for status <- [404, 503] do
        stub_iiif(status)

        log =
          capture_log(fn ->
            assert {:retry, _, _} =
                     send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})
          end)

        assert log =~ "HTTP error #{status}"
      end

      refute ActionStates.error?(file_set_id)
      refute Embeddings.get_file_set_embedding(file_set_id)
    end

    test "fails when the IIIF server refuses the request", %{file_set_id: file_set_id} do
      stub_iiif(403)

      log =
        capture_log(fn ->
          assert {:error, _, _} = send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})
        end)

      assert log =~ "error in image embedding"
      assert ActionStates.error?(file_set_id)
    end

    test "fails when the model fails", %{file_set_id: file_set_id} do
      stub_iiif()
      Stub.fail_with(:model_unavailable)

      capture_log(fn ->
        assert {:error, _, _} = send_test_message(EmbedImage, %{file_set_id: file_set_id}, %{})
      end)

      assert ActionStates.error?(file_set_id)
      refute Embeddings.get_file_set_embedding(file_set_id)
    end

    test "fails for a file set without an IIIF image" do
      file_set =
        file_set_fixture(%{role: %{id: "X", scheme: "FILE_SET_ROLE"}, derivatives: %{}})

      capture_log(fn ->
        assert {:error, _, _} = send_test_message(EmbedImage, %{file_set_id: file_set.id}, %{})
      end)

      assert ActionStates.error?(file_set.id)
    end
  end
end
