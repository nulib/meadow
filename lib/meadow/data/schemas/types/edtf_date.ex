defmodule Meadow.Data.Types.EDTFDate do
  @moduledoc """
  Ecto.Type for converting between edtf string and humanized date
  """

  use Ecto.Type
  alias Meadow.Data.Works

  def embed_as(:json), do: :dump

  def type, do: :map

  def cast(edtf_date), do: humanize(edtf_date)

  def load(edtf_date), do: humanize(edtf_date)

  def dump(nil), do: nil

  def dump(%{edtf_date: edtf_date, humanized_date: humanized_date}),
    do: {:ok, %{edtf_date: edtf_date, humanized_date: humanized_date}}

  def dump(_), do: :error

  defp humanize(nil), do: {:ok, nil}

  defp humanize(%{edtf_date: ""}),
    do: {:error, message: "edtf_date cannot be blank"}

  defp humanize(%{edtf_date: edtf_date, humanized_date: humanized_date}),
    do: {:ok, %{edtf_date: edtf_date, humanized_date: humanized_date}}

  defp humanize(%{"edtf_date" => edtf_date, "humanized_date" => humanized_date}),
    do: {:ok, %{edtf_date: edtf_date, humanized_date: humanized_date}}

  defp humanize(%{edtf_date: edtf_date}), do: humanize(edtf_date)

  defp humanize(edtf_date) when is_binary(edtf_date) do
    case Works.parse_edtf_date(edtf_date) do
      {:ok, %{edtf_date: edtf_date, humanized_date: humanized_date}} ->
        {:ok, %{edtf_date: edtf_date, humanized_date: humanized_date}}
    end
  end

  defp humanize(%{}), do: {:ok, nil}

  defp humanize(_), do: {:error, message: "Invalid edtf_date type"}
end
