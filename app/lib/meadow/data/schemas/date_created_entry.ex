defmodule Meadow.Data.Schemas.DateCreatedEntry do
  @moduledoc """
  One `date_created` value on a work (`work_dates_created`): the EDTF string
  and its humanized rendering.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "work_dates_created" do
    belongs_to :work, Meadow.Data.Schemas.Work
    field :position, :integer
    field :edtf, :string
    field :humanized, :string
  end

  def changeset(entry, params, position \\ nil) do
    entry
    |> cast(to_params(params), [:edtf])
    |> put_position(position)
    |> validate_required([:edtf])
    |> humanize()
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)

  defp humanize(%{valid?: false} = changeset), do: changeset

  defp humanize(changeset) do
    case fetch_change(changeset, :edtf) do
      {:ok, edtf} ->
        case EDTF.humanize(edtf, validate: false) do
          {:error, _} -> add_error(changeset, :edtf, "is not a valid EDTF date")
          humanized -> put_change(changeset, :humanized, humanized)
        end

      :error ->
        changeset
    end
  end

  @doc "Natural identity: the EDTF string"
  def natural_key(entry) do
    case to_params(entry) do
      %{edtf: edtf} -> edtf
      %{"edtf" => edtf} -> edtf
      _ -> nil
    end
  end

  @doc "Normalize a bare EDTF string or `{edtf, humanized}` map into params"
  def to_params(edtf) when is_binary(edtf), do: %{edtf: edtf}
  def to_params(%__MODULE__{id: id, edtf: edtf}), do: %{id: id, edtf: edtf}
  def to_params(%{} = map), do: map
  def to_params(other), do: other
end
