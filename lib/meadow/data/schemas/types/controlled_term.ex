defmodule Meadow.Data.Types.ControlledTerm do
  @moduledoc """
  Ecto.Type for converting between uri's and id, label pairs for controlled terms
  """

  use Ecto.Type
  def type, do: :string

  def cast(uri) when is_binary(uri), do: validate_uri(uri)
  def cast(%{id: id, label: _}), do: validate_uri(id)
  def cast(_), do: {:error, message: "Invalid controlled term type"}

  def load(uri) when is_binary(uri) do
    # TODO - replace with real lookup/cache call
    case Authoritex.fetch(uri) do
      {:ok, %{label: label}} ->
        {:ok, %{id: uri, label: label}}

      {:error, error} ->
        error
    end
  end

  def load(_), do: :error

  def dump(uri) when is_binary(uri), do: {:ok, uri}
  def dump(%{id: id, label: _}), do: id
  def dump(_), do: :error

  defp validate_uri(uri) do
    # TODO - replace with real lookup/cache call
    case Authoritex.fetch(uri) do
      {:ok, _result} ->
        {:ok, uri}

      {:error, error} ->
        {:error, message: error}
    end
  end
end
