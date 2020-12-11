defmodule Meadow.Data.Schemas.Batch do
  @moduledoc """
  Batch edit (update/delete) schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Data.Schemas.Work
  alias Meadow.Utils.ChangesetErrors

  @statuses ~w(queued in_progress complete error)
  @types ~w(update delete)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  schema "batches" do
    field :nickname, :string
    field :status, :string, default: "queued"
    field :user, :string
    field :started, :utc_datetime_usec
    field :type, :string
    field :works_updated, :integer
    field :query, :string
    field :add, :string
    field :delete, :string
    field :replace, :string
    field :error, :string
    field :active, :boolean, default: false

    many_to_many(
      :works,
      Work,
      join_through: "works_batches",
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(controlled_value, attrs) do
    controlled_value
    |> cast(attrs, [
      :nickname,
      :status,
      :user,
      :started,
      :type,
      :works_updated,
      :query,
      :add,
      :delete,
      :replace,
      :error,
      :active
    ])
    |> validate_required([:query, :type, :user])
    |> unique_constraint(:active)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
    |> validate_changes(:add)
    |> validate_changes(:replace)
  end

  defp validate_changes(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      "null" ->
        changeset

      changes ->
        work_changeset =
          Work.changeset(%Work{accession_number: "FAKE"}, Jason.decode!(changes, keys: :atoms))

        if work_changeset.valid? do
          changeset
        else
          error_response =
            work_changeset
            |> ChangesetErrors.error_details()
            |> ChangesetErrors.humanize_errors(
              flatten: [:administrative_metadata, :descriptive_metadata]
            )
            |> Jason.encode!()

          add_error(
            changeset,
            field,
            error_response
          )
        end
    end
  end
end
