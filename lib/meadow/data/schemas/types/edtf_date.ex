defmodule Meadow.Data.Types.EDTFDate do
  @moduledoc """
  Ecto.Type for converting between edtf string and humanized date
  """

  use Ecto.Type

  def embed_as(:json), do: :dump

  def type, do: :map

  def cast(edtf), do: humanize(edtf)

  def load(edtf), do: humanize(edtf)

  def dump(nil), do: nil

  def dump(%{edtf: edtf, humanized: humanized}),
    do: {:ok, %{edtf: edtf, humanized: humanized}}

  def dump(_), do: :error

  def from_string(value), do: %{edtf: value}

  defp humanize(nil), do: {:ok, nil}

  defp humanize(%{edtf: ""}),
    do: {:error, message: "cannot be blank"}

  defp humanize(%{edtf: edtf, humanized: humanized}),
    do: {:ok, %{edtf: edtf, humanized: humanized}}

  defp humanize(%{"edtf" => edtf, "humanized" => humanized}),
    do: {:ok, %{edtf: edtf, humanized: humanized}}

  defp humanize(%{edtf: edtf}), do: humanize(edtf)

  defp humanize(edtf) when is_binary(edtf) do
    case EDTF.humanize(edtf) do
      {:error, error} -> {:error, message: error}
      result -> {:ok, %{edtf: edtf, humanized: result}}
    end
  end

  defp humanize(%{}), do: {:ok, nil}

  defp humanize(_), do: {:error, message: "Invalid edtf type"}
end
