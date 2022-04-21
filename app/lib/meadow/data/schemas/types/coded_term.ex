defmodule Meadow.Data.Types.CodedTerm do
  @moduledoc """
  Ecto.Type for converting between uri's and id, label pairs for controlled terms
  """

  use Ecto.Type
  alias Meadow.Data.{CodedTerms, Schemas}

  def embed_as(:json), do: :dump

  def type, do: :map

  def cast(term), do: retrieve_term(term)

  def load(term), do: retrieve_term(term)

  def dump(nil), do: nil

  def dump(%Schemas.CodedTerm{id: id, scheme: scheme}),
    do: {:ok, %{id: id, scheme: scheme}}

  def dump(%{id: id, scheme: scheme}), do: {:ok, %{id: id, scheme: scheme}}
  def dump(_), do: :error

  def from_string(value), do: %{id: value}

  defp retrieve_term(nil), do: {:ok, nil}

  defp retrieve_term(%{id: "", scheme: _scheme}), do: {:error, message: "cannot have a blank id"}

  defp retrieve_term(%{"id" => id, "scheme" => scheme}),
    do: retrieve_term(%{id: id, scheme: scheme})

  defp retrieve_term(%{id: id, scheme: scheme}) do
    case CodedTerms.get_coded_term(id, scheme) do
      nil ->
        {:error, message: "is an invalid coded term for scheme #{String.upcase(scheme)}"}

      {{:ok, _}, %{id: id, scheme: scheme, label: label}} ->
        {:ok, %{id: id, scheme: scheme, label: label}}

      other ->
        {:error, other}
    end
  end

  defp retrieve_term(%{}), do: {:ok, nil}

  defp retrieve_term(_), do: {:error, message: "is invalid"}
end
