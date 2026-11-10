defmodule Meadow.Embeddings.ModelFilesTest do
  use ExUnit.Case, async: false

  alias Meadow.Embeddings.ModelFiles

  setup do
    config = Application.get_env(:meadow, Meadow.Embeddings)
    {:ok, model_dir} = Briefly.create(type: :directory)

    Application.put_env(
      :meadow,
      Meadow.Embeddings,
      Keyword.merge(config,
        model_dir: model_dir,
        auto_download: true,
        req_options: [plug: {Req.Test, __MODULE__}, retry: false]
      )
    )

    on_exit(fn -> Application.put_env(:meadow, Meadow.Embeddings, config) end)
    {:ok, model_dir: model_dir}
  end

  test "paths mirror the repository layout under the model directory", %{model_dir: model_dir} do
    root = Path.join(model_dir, "onnx-community/embeddinggemma-2-ONNX/main")
    assert ModelFiles.dir() == root
    assert ModelFiles.model_path() == Path.join(root, "onnx/model.onnx")
    assert ModelFiles.tokenizer_path() == Path.join(root, "tokenizer.json")
    refute ModelFiles.available?()
  end

  test "ensure/0 downloads the tokenizer, the graph and its external data" do
    Req.Test.stub(__MODULE__, fn conn ->
      Plug.Conn.send_resp(conn, 200, "contents of #{conn.request_path}")
    end)

    assert ModelFiles.ensure() == :ok
    assert ModelFiles.available?()

    assert File.read!(ModelFiles.model_path()) ==
             "contents of /onnx-community/embeddinggemma-2-ONNX/resolve/main/onnx/model.onnx"

    assert File.exists?(ModelFiles.model_path() <> "_data")
    assert Path.wildcard(Path.join(ModelFiles.dir(), "**/*.part")) == []
  end

  test "the vision encoder is a separate component" do
    refute ModelFiles.available?(:vision)

    Req.Test.stub(__MODULE__, fn conn ->
      Plug.Conn.send_resp(conn, 200, "contents of #{conn.request_path}")
    end)

    assert ModelFiles.ensure(:vision) == :ok
    assert ModelFiles.available?(:vision)
    refute ModelFiles.available?(:text)

    assert File.read!(ModelFiles.vision_model_path()) ==
             "contents of /onnx-community/embeddinggemma-2-ONNX/resolve/main/onnx/vision_encoder.onnx"

    assert File.exists?(ModelFiles.vision_model_path() <> "_data")
  end

  test "ensure/0 does not download files that are already present" do
    for file <- ModelFiles.files() do
      path = Path.join(ModelFiles.dir(), file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "cached")
    end

    Req.Test.stub(__MODULE__, fn _conn -> flunk("unexpected download") end)
    assert ModelFiles.ensure() == :ok
  end

  test "a failed download leaves no partial file behind" do
    Req.Test.stub(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 404, "Not Found") end)

    assert {:error, {:download_failed, url, 404}} = ModelFiles.ensure()
    assert url =~ "/resolve/main/tokenizer.json"
    refute ModelFiles.available?()
    assert Path.wildcard(Path.join(ModelFiles.dir(), "**/*")) |> Enum.reject(&File.dir?/1) == []
  end

  test "ensure/0 reports missing files when downloads are disabled" do
    config = Application.get_env(:meadow, Meadow.Embeddings)
    Application.put_env(:meadow, Meadow.Embeddings, Keyword.put(config, :auto_download, false))

    assert ModelFiles.ensure() == {:error, {:model_files_missing, ModelFiles.dir()}}
  end
end
