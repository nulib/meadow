defmodule Meadow.Data.Types.EDTFDate do
  @moduledoc """
  Helpers for EDTF date values. Dates are stored as
  `Meadow.Data.Schemas.DateCreatedEntry` rows; this module keeps the parsing
  and humanizing helpers used by CSV import and batch updates.
  """

  def from_string(value), do: %{edtf: value}

  @doc "Humanize an EDTF string or `{edtf}` map into `{:ok, %{edtf, humanized}}`"
  def humanize(nil), do: {:ok, nil}
  def humanize(%{edtf: ""}), do: {:error, message: "cannot be blank"}

  def humanize(%{edtf: edtf, humanized: humanized}),
    do: {:ok, %{edtf: edtf, humanized: humanized}}

  def humanize(%{"edtf" => edtf, "humanized" => humanized}),
    do: {:ok, %{edtf: edtf, humanized: humanized}}

  def humanize(%{"edtf" => edtf}), do: humanize(edtf)
  def humanize(%{edtf: edtf}), do: humanize(edtf)
  def humanize(""), do: {:error, message: "cannot be blank"}

  def humanize(edtf) when is_binary(edtf) do
    case EDTF.humanize(edtf, validate: false) do
      {:error, _} -> :error
      result -> {:ok, %{edtf: edtf, humanized: result}}
    end
  end

  def humanize(%{}), do: {:ok, nil}
  def humanize(_), do: {:error, message: "Invalid edtf type"}
end
