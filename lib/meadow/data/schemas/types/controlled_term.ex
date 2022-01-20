defmodule Meadow.Data.Types.ControlledTerm do
  @moduledoc """
  Ecto.Type for converting between uri's and id, label pairs for controlled terms
  """

  use Ecto.Type
  alias Meadow.Data.ControlledTerms

  def embed_as(:json), do: :dump

  def type, do: :string

  def cast(uri) when is_binary(uri), do: validate_uri(uri)
  def cast(nil), do: {:error, message: "has a nil URI"}
  def cast(%{id: id}), do: validate_uri(id)
  def cast(%{"id" => id}), do: validate_uri(id)
  def cast(_), do: {:error, message: "Invalid controlled term type"}

  def load(uri) when is_binary(uri), do: validate_uri(uri)
  def load(nil), do: :error
  def load(%{id: id}), do: validate_uri(id)
  def load(%{"id" => id}), do: validate_uri(id)
  def load(_), do: :error

  def dump(uri) when is_binary(uri), do: {:ok, uri}
  def dump(nil), do: :error
  def dump(%{id: id}), do: {:ok, id}
  def dump(%{"id" => id}), do: {:ok, id}
  def dump(_), do: :error

  defp validate_uri(nil), do: {:error, message: "has a nil id"}

  defp validate_uri(uri) do
    with id <- munge_uri(uri) do
      case ControlledTerms.fetch(id) do
        {{:ok, _}, %{label: label, variants: variants}} ->
          {:ok, %{id: id, label: label, variants: variants}}

        {:error, error} ->
          Meadow.Error.report(error, __MODULE__, [], %{id: id})
          {:error, message: error}
      end
    end
  end

  def munge_uri("http://sws.geonames.org" <> _ = id) do
    with uri <- URI.parse(id),
         path <- ensure_trailing_slash(uri.path) do
      %URI{uri | scheme: "https", port: 443, path: path} |> URI.to_string()
    end
  end

  def munge_uri("https://sws.geonames.org" <> _ = id), do: ensure_trailing_slash(id)

  def munge_uri(id), do: id

  defp ensure_trailing_slash(path) do
    if String.ends_with?(path, "/"),
      do: path,
      else: path <> "/"
  end
end
