defmodule NUL.Schemas.AuthorityRecord do
  @moduledoc """
  AuthorityRecords are used to describe local controlled vocabulary entries.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, []}
  schema "authority_records" do
    field :label, :string
    field :hint, :string

    timestamps()
  end

  def changeset(record, params) do
    record
    |> cast(params, [:label, :hint])
    |> validate_required([:label])
    |> unique_constraint(:label)
    |> put_change(:id, generate_nul_id())
  end

  def update_changeset(record, params) do
    record
    |> cast(params, [:label, :hint])
    |> unique_constraint(:label)
  end

  defp generate_nul_id do
    "info:nul/" <> Ecto.UUID.generate()
  end
end
