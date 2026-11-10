defmodule Meadow.Embeddings.Prompt do
  @moduledoc """
  EmbeddingGemma task prompts. The model is trained with these prefixes, and
  retrieval quality depends on queries and documents each using their own.

  dc-api-v2 embeds search text with the same query prompt; the two must stay
  in sync.
  """

  @doc """
  Prompt for a document to be retrieved

      iex> Meadow.Embeddings.Prompt.document("Poster", "subject: Jazz")
      "title: Poster | text: subject: Jazz"

      iex> Meadow.Embeddings.Prompt.document(nil, "subject: Jazz")
      "title: none | text: subject: Jazz"
  """
  def document(title, text), do: "title: #{title(title)} | text: #{text}"

  @doc """
  Prompt for a search query

      iex> Meadow.Embeddings.Prompt.query("jazz posters")
      "task: search result | query: jazz posters"
  """
  def query(text), do: "task: search result | query: #{text}"

  defp title(title) when is_binary(title) do
    case title |> String.replace(~r/\s+/, " ") |> String.trim() do
      "" -> "none"
      title -> title
    end
  end

  defp title(_), do: "none"
end
