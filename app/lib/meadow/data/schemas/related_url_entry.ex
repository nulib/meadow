defmodule Meadow.Data.Schemas.RelatedURLEntry do
  @moduledoc """
  One related URL on a work (`work_related_urls`): a URL plus a `related_url`
  coded-term label.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.Types

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "work_related_urls" do
    belongs_to :work, Meadow.Data.Schemas.Work
    field :position, :integer
    field :url, :string
    field :label, Types.CodedTerm, scheme: "related_url", source: :label_id
  end

  def changeset(metadata, params, position \\ nil) do
    metadata
    |> cast(params, [:url, :label])
    |> put_position(position)
    |> validate_required([:url, :label])
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)

  @doc "Natural identity: `{url, label_id}`"
  def natural_key(entry) do
    label = Map.get(entry, :label) || Map.get(entry, "label")
    {Map.get(entry, :url) || Map.get(entry, "url"), coded_id(label)}
  end

  defp coded_id(%{id: id}), do: id
  defp coded_id(%{"id" => id}), do: id
  defp coded_id(id) when is_binary(id), do: id
  defp coded_id(_), do: nil

  def to_params(%__MODULE__{id: id, url: url, label: label}),
    do: %{id: id, url: url, label: label && %{id: label.id, scheme: label.scheme}}

  def to_params(%{} = map), do: map

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
