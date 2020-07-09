defmodule Meadow.Data.Types.ControlledTerm do
  @moduledoc """
  Ecto.Type for converting between uri's and id, label pairs for controlled terms
  """

  use Ecto.Type
  alias Meadow.Data.ControlledTerms

  def embed_as(:json), do: :dump

  def type, do: :string

  def cast(uri) when is_binary(uri), do: validate_uri(uri)
  def cast(%{id: id}), do: validate_uri(id)
  def cast(%{"id" => id}), do: validate_uri(id)
  def cast(_), do: {:error, message: "Invalid controlled term type"}

  def load(uri) when is_binary(uri), do: validate_uri(uri)
  def load(_), do: :error

  def dump(uri) when is_binary(uri), do: {:ok, uri}
  def dump(%{id: id}), do: {:ok, id}
  def dump(%{"id" => id}), do: {:ok, id}
  def dump(_), do: :error

  defp validate_uri(uri) do
    # replace with real lookup/cache call
    case ControlledTerms.fetch(uri) do
      {{:ok, _}, %{label: label}} ->
        {:ok, %{id: uri, label: label}}

      {:error, error} ->
        {:error, message: error}
    end
  end
end
