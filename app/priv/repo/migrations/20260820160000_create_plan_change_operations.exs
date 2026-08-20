defmodule Meadow.Repo.Migrations.CreatePlanChangeOperations do
  @moduledoc """
  Move plan change `add`/`delete`/`replace` operation maps out of jsonb into
  `plan_change_operations`, one typed row per proposed item. Existing changes
  are backfilled through the same codec the application uses
  (`Meadow.Data.Planner.Operations`); the jsonb columns stay until the cleanup
  migration. `down/0` drops the table.
  """

  use Ecto.Migration

  require Logger

  def up do
    create table(:plan_change_operations, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:plan_change_id, references(:plan_changes, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:operation, :text, null: false)
      add(:section, :text)
      add(:field, :text, null: false)
      add(:position, :integer)
      add(:value_kind, :text, null: false)
      add(:value_text, :text)
      add(:term_id, :text)
      add(:term_label, :text)
      add(:role_id, :text)
      add(:role_scheme, :text)
      add(:role_label, :text)
      add(:coded_id, :text)
      add(:coded_scheme, :text)
      add(:coded_label, :text)
      add(:edtf, :text)
      add(:humanized, :text)
    end

    create(
      constraint(:plan_change_operations, :operation_must_be_known,
        check: "operation IN ('add', 'delete', 'replace')"
      )
    )

    create(
      constraint(:plan_change_operations, :section_must_be_known,
        check: "section IS NULL OR section IN ('descriptive_metadata', 'administrative_metadata')"
      )
    )

    create(
      constraint(:plan_change_operations, :value_kind_must_be_known,
        check:
          "value_kind IN ('string', 'controlled', 'coded', 'edtf', 'note', 'related_url', 'boolean', 'null')"
      )
    )

    create(
      index(:plan_change_operations, [:plan_change_id, :operation, :section, :field, :position])
    )

    create(index(:plan_change_operations, [:term_id]))

    flush()
    backfill()
  end

  def down do
    drop(table(:plan_change_operations))
  end

  defp backfill do
    Logger.info("Backfilling plan_change_operations")

    %{rows: rows} =
      repo().query!("""
      SELECT id::text,
             COALESCE(add, '{}'::jsonb)::text,
             COALESCE("delete", '{}'::jsonb)::text,
             COALESCE(replace, '{}'::jsonb)::text
      FROM plan_changes
      """)

    {ok, skipped} =
      Enum.reduce(rows, {0, 0}, fn [change_id, add, delete, replace], {ok, skipped} ->
        operations = %{
          add: Jason.decode!(add),
          delete: Jason.decode!(delete),
          replace: Jason.decode!(replace)
        }

        case Meadow.Data.Planner.Operations.to_rows(operations) do
          {:ok, []} ->
            {ok, skipped}

          {:ok, attrs} ->
            insert_rows!(change_id, attrs)
            {ok + 1, skipped}

          {:error, message} ->
            Logger.warning("Skipping plan change #{change_id}: #{message}")
            {ok, skipped + 1}
        end
      end)

    Logger.info("Backfilled operations for #{ok} plan changes (#{skipped} skipped)")
  end

  @columns ~w(plan_change_id operation section field position value_kind value_text term_id term_label
    role_id role_scheme role_label coded_id coded_scheme coded_label edtf humanized)a

  defp insert_rows!(change_id, attrs) do
    attrs
    |> Enum.chunk_every(200)
    |> Enum.each(fn chunk ->
      {placeholders, params} =
        chunk
        |> Enum.with_index()
        |> Enum.map_reduce([], fn {row, i}, acc ->
          row = Map.put(row, :plan_change_id, change_id)
          base = i * length(@columns)

          placeholder =
            @columns
            |> Enum.with_index(1)
            |> Enum.map_join(", ", fn
              {:plan_change_id, n} -> "$#{base + n}::uuid"
              {:position, n} -> "$#{base + n}::integer"
              {_, n} -> "$#{base + n}"
            end)

          {"(#{placeholder})", acc ++ Enum.map(@columns, &Map.get(row, &1))}
        end)

      repo().query!(
        "INSERT INTO plan_change_operations (#{Enum.join(@columns, ", ")}) VALUES #{Enum.join(placeholders, ", ")}",
        params
      )
    end)
  end
end
