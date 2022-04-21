defmodule Meadow.Data.Schemas.RelatedURLEntry do
  @moduledoc """
  Schema for Related URL
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key false
  embedded_schema do
    field :url, :string
    field :label, Types.CodedTerm
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [:url, :label])
    |> validate_required([:url, :label])
  end

  def from_string(""), do: nil

  def from_string(value) when is_binary(value) do
    String.split(value, ":", parts: 2)
    |> from_string_result()
  end

  defp from_string_result([role_id | [url | []]] = value) do
    case URI.parse(url) do
      %{scheme: nil} -> %{url: Enum.join(value, ":")}
      _ -> %{label: %{id: role_id, scheme: "related_url"}, url: url}
    end
  end

  defp from_string_result(value), do: %{url: Enum.join(value, ":")}
end
