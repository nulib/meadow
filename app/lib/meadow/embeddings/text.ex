defmodule Meadow.Embeddings.Text do
  @moduledoc """
  Builds the text a work is embedded from, using the work's index document
  (`Meadow.Indexing.V2.Work.encode/1`) as the source so the embedding sees
  the same labels the search index does.
  """

  alias Meadow.Embeddings.{Config, Prompt}

  defstruct [:title, :text, :length, :prompt, :hash]

  @type t :: %__MODULE__{
          title: String.t() | nil,
          text: String.t(),
          length: non_neg_integer(),
          prompt: String.t(),
          hash: String.t()
        }

  @doc """
  Build the embedding text for an index document.

  * `text` is one `field: value` line per configured, non-empty field,
    truncated to the configured byte limit
  * `length` is the length of the text before truncation
  * `prompt` is what is actually sent to the model
  * `hash` identifies the prompt, so unchanged works are not embedded again
  """
  @spec build(map()) :: t()
  def build(document) when is_map(document) do
    full_text =
      Config.text_fields()
      |> Enum.map(fn field -> {field, document |> Map.get(field) |> value() |> concatenate()} end)
      |> Enum.reject(fn {_, value} -> is_nil(value) or value == "" end)
      |> Enum.map_join("\n", fn {field, value} -> "#{field}: #{value}" end)

    title = document |> Map.get(:title) |> value() |> concatenate()
    text = truncate(full_text, Config.max_text_length())
    prompt = Prompt.document(title, text)

    %__MODULE__{
      title: title,
      text: text,
      length: String.length(full_text),
      prompt: prompt,
      hash: hash(prompt)
    }
  end

  @doc "Hex-encoded SHA-256 digest of a prompt"
  def hash(prompt), do: :crypto.hash(:sha256, prompt) |> Base.encode16(case: :lower)

  @doc "Truncate a string to a byte limit without splitting a character"
  def truncate(string, byte_limit) when byte_size(string) <= byte_limit, do: string

  def truncate(string, byte_limit) do
    string
    |> String.graphemes()
    |> Enum.reduce_while("", fn grapheme, acc ->
      if byte_size(acc) + byte_size(grapheme) > byte_limit,
        do: {:halt, acc},
        else: {:cont, acc <> grapheme}
    end)
  end

  defp concatenate(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.join("; ")
  end

  defp concatenate(value), do: value

  defp value(%{label_with_role: value}), do: value(value)
  defp value(%{label: value}), do: value(value)
  defp value(%{title: value}), do: value(value)
  defp value(values) when is_list(values), do: Enum.map(values, &value/1)
  defp value(value) when is_binary(value), do: value
  defp value(_), do: nil
end
