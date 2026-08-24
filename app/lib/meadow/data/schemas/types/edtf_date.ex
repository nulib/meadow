defmodule Meadow.Data.Types.EDTFDate do
  @moduledoc """
  Ecto type for EDTF dates.

  The column stores only the EDTF string; `humanized` is derived on load, so a
  change to the humanizer can never leave stale renderings in the database.
  Values load as `%{edtf, humanized}` so callers keep reading `.humanized`.
  """

  use Ecto.Type

  @invalid "is not a valid EDTF date"

  def type, do: :string

  def embed_as(_format), do: :dump

  def cast(value), do: humanize(value)

  # Stored values were valid when written; a humanizer change should degrade to
  # the raw string rather than fail the whole load
  def load(edtf) when is_binary(edtf) do
    case humanize(edtf) do
      {:ok, value} -> {:ok, value}
      _ -> {:ok, %{edtf: edtf, humanized: edtf}}
    end
  end

  def load(nil), do: {:ok, nil}
  def load(_), do: :error

  def dump(nil), do: {:ok, nil}
  def dump(edtf) when is_binary(edtf), do: {:ok, edtf}
  def dump(%{edtf: edtf}) when is_binary(edtf), do: {:ok, edtf}
  def dump(%{"edtf" => edtf}) when is_binary(edtf), do: {:ok, edtf}
  def dump(_), do: :error

  @doc "The EDTF string of a date value, whatever shape it arrived in"
  def edtf(%{edtf: edtf}), do: edtf
  def edtf(%{"edtf" => edtf}), do: edtf
  def edtf(edtf) when is_binary(edtf), do: edtf
  def edtf(_), do: nil

  @doc "Normalize a bare EDTF string into params (kept for CSV import and batches)"
  def from_string(value), do: %{edtf: value}

  @doc "Whether a value is a castable EDTF date; used for per-item error reporting"
  def valid?(value), do: match?({:ok, _}, humanize(value))

  defp humanize(nil), do: {:ok, nil}
  defp humanize(""), do: {:error, message: "cannot be blank"}
  defp humanize(%{edtf: ""}), do: {:error, message: "cannot be blank"}
  defp humanize(%{"edtf" => ""}), do: {:error, message: "cannot be blank"}

  defp humanize(edtf) when is_binary(edtf) do
    case EDTF.humanize(edtf, validate: false) do
      {:error, _} -> {:error, message: @invalid}
      humanized -> {:ok, %{edtf: edtf, humanized: humanized}}
    end
  end

  defp humanize(%{edtf: edtf}) when is_binary(edtf), do: humanize(edtf)
  defp humanize(%{"edtf" => edtf}) when is_binary(edtf), do: humanize(edtf)
  defp humanize(%{}), do: {:ok, nil}
  defp humanize(_), do: {:error, message: "Invalid edtf type"}
end
