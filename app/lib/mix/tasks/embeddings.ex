defmodule Mix.Tasks.Meadow.Embeddings.Backfill do
  @moduledoc """
  Generate embeddings for existing works and image file sets

      mix meadow.embeddings.backfill              # works and file sets without an embedding
      mix meadow.embeddings.backfill --works      # works only
      mix meadow.embeddings.backfill --file-sets  # image file sets only
      mix meadow.embeddings.backfill --all        # check every work, re-embed every file set

  The search index is updated by the running application as embeddings are
  written. If no Meadow instance is running, reindex afterwards with
  `Meadow.Data.Indexer.reindex_all()`.
  """
  use Mix.Task

  alias Meadow.Embeddings

  @shortdoc "Generate embeddings for existing works and image file sets"
  def run(args) do
    {opts, _} =
      OptionParser.parse!(args, strict: [works: :boolean, file_sets: :boolean, all: :boolean])

    scope = if opts[:all], do: :all, else: :missing
    both = not Keyword.has_key?(opts, :works) and not Keyword.has_key?(opts, :file_sets)

    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")
    {:ok, _} = Embeddings.Model.ONNX.start_link([])

    if both or opts[:works], do: backfill_works(scope)
    if both or opts[:file_sets], do: backfill_file_sets(scope)
  end

  defp backfill_works(scope) do
    case Embeddings.backfill(scope: scope) do
      {:ok, count} -> Mix.shell().info("Embedded #{count} works")
      {:error, reason} -> Mix.raise("Work embedding failed: #{inspect(reason)}")
    end
  end

  defp backfill_file_sets(scope) do
    {:ok, %{embedded: count, failed: failed}} = Embeddings.backfill_file_sets(scope: scope)
    Mix.shell().info("Embedded #{count} file sets")

    for {file_set_id, reason} <- failed do
      Mix.shell().error("Could not embed file set #{file_set_id}: #{inspect(reason)}")
    end
  end
end

defmodule Mix.Tasks.Meadow.Embeddings.Download do
  @moduledoc """
  Download the embedding model, vision encoder and tokenizer into the model cache directory

      mix meadow.embeddings.download

  The destination is `EMBEDDING_MODEL_DIR` (see `Meadow.Embeddings.ModelFiles`).
  Run this at image build time so nodes do not download the model on first use.
  """
  use Mix.Task

  alias Meadow.Embeddings.ModelFiles

  @shortdoc "Download the embedding model and tokenizer"
  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.config")
    {:ok, _} = Application.ensure_all_started(:req)

    with :ok <- ModelFiles.download(:text),
         :ok <- ModelFiles.download(:vision) do
      Mix.shell().info("Embedding model available in #{ModelFiles.dir()}")
    else
      {:error, reason} -> Mix.raise("Embedding model download failed: #{inspect(reason)}")
    end
  end
end
