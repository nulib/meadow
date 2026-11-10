defmodule Meadow.Embeddings.Model.ONNX do
  @moduledoc """
  Runs an EmbeddingGemma ONNX export with ONNX Runtime (via `Ortex`) and the
  model's own tokenizer.

  The model and tokenizer are loaded on first use, so a node only pays the
  memory cost once it actually embeds something. Inference is serialized
  through this process; ONNX Runtime already spreads a single run across the
  available cores.

  The graph's last output is the pooled, L2-normalized sentence embedding.
  Besides `input_ids` and `attention_mask` it takes image, video and audio
  feature inputs, which are passed as empty tensors when unused.

  Images go through a separate vision encoder (loaded the first time an
  image is embedded) that produces one feature row per soft token. The text
  model receives those rows together with a matching run of image
  placeholder tokens.
  """

  @behaviour Meadow.Embeddings.Model

  use GenServer

  alias Meadow.Embeddings.{Config, ImageInput, ModelFiles}
  alias Tokenizers.{Encoding, Tokenizer}

  require Logger

  # Width of the image, video and audio feature inputs
  @feature_size 512
  @pad_id 0

  # Placeholder tokens for one image: begin, one per soft token, end
  @image_start "<|image>"
  @image_token "<|image|>"
  @image_end "<image|>"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl Meadow.Embeddings.Model
  def embed(prompts), do: embed(__MODULE__, prompts)

  @doc "Embed a list of prompts using a specific server"
  def embed(_server, []), do: {:ok, []}

  def embed(server, prompts) when is_list(prompts) do
    GenServer.call(server, {:embed, prompts}, :infinity)
  end

  @impl Meadow.Embeddings.Model
  def embed_image(image), do: embed_image(__MODULE__, image)

  @doc "Embed an encoded image using a specific server"
  def embed_image(server, image) when is_binary(image) do
    GenServer.call(server, {:embed_image, image}, :infinity)
  end

  @impl GenServer
  def init(_opts), do: {:ok, %{model: nil, tokenizer: nil, vision: nil}}

  @impl GenServer
  def handle_call({:embed, prompts}, _from, state) do
    with {:ok, state} <- ensure_loaded(state),
         {:ok, vectors} <- run(state, prompts) do
      {:reply, {:ok, vectors}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:embed_image, image}, _from, state) do
    with {:ok, state} <- ensure_loaded(state),
         {:ok, state} <- ensure_vision_loaded(state),
         {:ok, input} <- ImageInput.prepare(image, Config.image_soft_tokens()),
         {:ok, vector} <- run_image(state, input) do
      {:reply, {:ok, vector}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp ensure_vision_loaded(%{vision: nil} = state) do
    with :ok <- ModelFiles.ensure(:vision) do
      Logger.info("Loading vision encoder from #{ModelFiles.vision_model_path()}")
      {:ok, %{state | vision: Ortex.load(ModelFiles.vision_model_path())}}
    end
  rescue
    exception -> {:error, exception}
  end

  defp ensure_vision_loaded(state), do: {:ok, state}

  defp ensure_loaded(%{model: nil} = state) do
    with :ok <- ModelFiles.ensure() do
      Logger.info("Loading embedding model from #{ModelFiles.model_path()}")
      {:ok, %{state | model: Ortex.load(ModelFiles.model_path()), tokenizer: load_tokenizer!()}}
    end
  rescue
    exception -> {:error, exception}
  end

  defp ensure_loaded(state), do: {:ok, state}

  defp load_tokenizer! do
    {:ok, tokenizer} = Tokenizer.from_file(ModelFiles.tokenizer_path())

    tokenizer
    |> Tokenizer.set_truncation(max_length: Config.max_tokens())
    |> Tokenizer.disable_padding()
  end

  # Inputs are grouped by length so each batch pads as little as possible,
  # then the vectors are put back in the order the prompts arrived in.
  defp run(%{model: model, tokenizer: tokenizer}, prompts) do
    with {:ok, encodings} <- Tokenizer.encode_batch(tokenizer, prompts) do
      vectors =
        encodings
        |> Enum.map(&Encoding.get_ids/1)
        |> Enum.with_index()
        |> Enum.sort_by(fn {ids, _} -> length(ids) end)
        |> Enum.chunk_every(Config.batch_size())
        |> Enum.flat_map(&run_batch(model, &1))
        |> Enum.sort_by(fn {_, index} -> index end)
        |> Enum.map(fn {vector, _} -> vector end)

      {:ok, vectors}
    end
  rescue
    exception -> {:error, exception}
  end

  defp run_batch(model, batch) do
    {ids, indexes} = Enum.unzip(batch)
    width = ids |> Enum.map(&length/1) |> Enum.max()

    input_ids = Nx.tensor(Enum.map(ids, &pad(&1, width, @pad_id)), type: :s64)
    attention_mask = Nx.tensor(Enum.map(ids, &mask(&1, width)), type: :s64)

    model
    |> sentence_embeddings(input_ids, attention_mask, empty_features())
    |> Enum.zip(indexes)
  end

  defp run_image(%{model: model, tokenizer: tokenizer, vision: vision}, %ImageInput{} = input) do
    prompt = @image_start <> String.duplicate(@image_token, input.soft_tokens) <> @image_end

    with {:ok, encoding} <- Tokenizer.encode(tokenizer, prompt) do
      ids = Encoding.get_ids(encoding)
      {image_features} = Ortex.run(vision, {input.pixel_values, input.position_ids})

      [vector] =
        sentence_embeddings(
          model,
          Nx.tensor([ids], type: :s64),
          Nx.tensor([List.duplicate(1, length(ids))], type: :s64),
          image_features
        )

      {:ok, vector}
    end
  rescue
    exception -> {:error, exception}
  end

  # Runs the main model; video and audio features are always empty
  defp sentence_embeddings(model, input_ids, attention_mask, image_features) do
    model
    |> Ortex.run({input_ids, attention_mask, image_features, empty_features(), empty_features()})
    |> Tuple.to_list()
    |> List.last()
    |> Nx.backend_transfer(Nx.BinaryBackend)
    |> Nx.to_list()
  end

  defp pad(ids, width, value), do: ids ++ List.duplicate(value, width - length(ids))

  defp mask(ids, width),
    do: List.duplicate(1, length(ids)) ++ List.duplicate(0, width - length(ids))

  # Nx cannot build a tensor with a zero-sized dimension, so the empty
  # `{0, feature_size}` inputs are created directly on the Ortex backend.
  defp empty_features do
    Ortex.Backend.from_binary(
      %Nx.Tensor{shape: {0, @feature_size}, type: {:f, 32}, names: [nil, nil], data: nil},
      <<>>,
      []
    )
  end
end
