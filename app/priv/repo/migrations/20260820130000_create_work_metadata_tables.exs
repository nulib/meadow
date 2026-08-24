defmodule Meadow.Repo.Migrations.CreateWorkMetadataTables do
  @moduledoc """
  Move work descriptive/administrative metadata out of the `works` jsonb
  columns.

  A child table is created only where one earns its keep — where it carries a
  foreign key to `coded_terms` or is queried relationally:

    * `work_descriptive_metadata`, `work_administrative_metadata` (one row per
      work) hold scalars and coded terms as columns, repeating free text and
      EDTF dates as `text[]`, and places as embedded jsonb
    * `work_controlled_entries` (queried by term and role; role has a foreign key)
    * `work_notes`, `work_related_urls` (note type and URL label have foreign keys)

  Existing data is backfilled from the jsonb columns, which are left in place
  (unused) until the cleanup migration drops them. The `work_terms` projection
  table and the jsonb batch-update functions are replaced by the new tables and
  dropped here. Forward-only for data: `down/0` drops the new tables, the jsonb
  columns still hold the original data.
  """

  use Ecto.Migration

  require Logger

  @descriptive_values ~w(abstract alternate_title box_name box_number caption catalog_key citation
    cultural_context description folder_name folder_number identifier keywords legacy_identifier
    physical_description_material physical_description_size provenance publisher related_material
    rights_holder scope_and_contents series source table_of_contents)

  @administrative_values ~w(project_name project_desc project_proposer project_manager project_task_number)

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)

  @role_fields ~w(contributor subject)

  @metadata_tables ~w(work_descriptive_metadata work_administrative_metadata
    work_controlled_entries work_notes work_related_urls)

  def up do
    create_tables()
    flush()
    preflight!()

    execute("ALTER PUBLICATION events DROP TABLE works")

    backfill()
    flush()
    verify!()

    execute("ALTER PUBLICATION events ADD TABLE works, #{Enum.join(@metadata_tables, ", ")}")
    Enum.each(@metadata_tables, &execute("ALTER TABLE #{&1} REPLICA IDENTITY FULL"))

    drop_legacy_objects()
  end

  def down do
    execute("ALTER PUBLICATION events DROP TABLE #{Enum.join(@metadata_tables, ", ")}")

    Enum.each(Enum.reverse(@metadata_tables), fn table ->
      execute("DROP TABLE IF EXISTS #{table}")
    end)

    Enum.each(
      ~w(works:visibility works:work_type works:behavior collections:visibility file_sets:role),
      fn spec ->
        [table, column] = String.split(spec, ":")
        execute("ALTER TABLE #{table} DROP COLUMN IF EXISTS #{column}_scheme")
      end
    )
  end

  # ---------------------------------------------------------------------------
  # schema

  defp create_tables do
    create table(:work_descriptive_metadata, primary_key: false) do
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), primary_key: true)

      Enum.each(@descriptive_values, fn field ->
        add(String.to_atom(field), {:array, :text}, null: false, default: [])
      end)

      add(:title, :text)
      add(:terms_of_use, :text)
      add(:date_created, {:array, :text}, null: false, default: [])
      add(:nav_place, :map, null: false, default: fragment("'[]'::jsonb"))
      add(:license_id, :text)
      add(:license_scheme, :text, generated: "ALWAYS AS ('license') STORED")
      add(:rights_statement_id, :text)
      add(:rights_statement_scheme, :text, generated: "ALWAYS AS ('rights_statement') STORED")
      timestamps(type: :utc_datetime_usec)
    end

    coded_fk(:work_descriptive_metadata, :license)
    coded_fk(:work_descriptive_metadata, :rights_statement)
    create(index(:work_descriptive_metadata, [:title]))

    create table(:work_administrative_metadata, primary_key: false) do
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), primary_key: true)

      Enum.each(@administrative_values, fn field ->
        add(String.to_atom(field), {:array, :text}, null: false, default: [])
      end)

      add(:library_unit_id, :text)
      add(:library_unit_scheme, :text, generated: "ALWAYS AS ('library_unit') STORED")
      add(:preservation_level_id, :text)
      add(:preservation_level_scheme, :text, generated: "ALWAYS AS ('preservation_level') STORED")
      add(:status_id, :text)
      add(:status_scheme, :text, generated: "ALWAYS AS ('status') STORED")
      add(:project_cycle, :text)
      timestamps(type: :utc_datetime_usec)
    end

    coded_fk(:work_administrative_metadata, :library_unit)
    coded_fk(:work_administrative_metadata, :preservation_level)
    coded_fk(:work_administrative_metadata, :status)

    create table(:work_controlled_entries, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:field, :text, null: false)
      add(:position, :integer, null: false)
      add(:term_id, :text, null: false)
      add(:role_id, :text)

      # The role's scheme is a function of the field, so it is derived rather
      # than stored by the application; the pair still carries a real FK.
      add(:role_scheme, :text, generated: "ALWAYS AS (#{role_scheme_expression()}) STORED")
    end

    create(
      constraint(:work_controlled_entries, :field_must_be_known,
        check: "field IN (#{quoted_list(@controlled_fields)})"
      )
    )

    create(
      constraint(:work_controlled_entries, :only_role_fields_carry_a_role,
        check: "role_id IS NULL OR field IN (#{quoted_list(@role_fields)})"
      )
    )

    execute("""
    ALTER TABLE work_controlled_entries
      ADD CONSTRAINT work_controlled_entries_role_fkey
      FOREIGN KEY (role_id, role_scheme) REFERENCES coded_terms (id, scheme)
    """)

    create(index(:work_controlled_entries, [:work_id, :field]))

    # Leading `term_id` also serves term-only lookups, so this one index covers
    # search by term, by term and role, and by term, role and field
    create(index(:work_controlled_entries, [:term_id, :role_id, :field]))

    # An entry's identity is its natural key; `id` is only a technical primary key
    execute("""
    CREATE UNIQUE INDEX work_controlled_entries_natural_key
      ON work_controlled_entries (work_id, field, term_id, COALESCE(role_id, ''))
    """)

    deferrable_unique(:work_controlled_entries, ~w(work_id field position))

    create table(:work_notes, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:position, :integer, null: false)
      add(:note, :text, null: false)
      add(:type_id, :text, null: false)
      add(:type_scheme, :text, generated: "ALWAYS AS ('note_type') STORED")
    end

    coded_fk(:work_notes, :type)
    create(index(:work_notes, [:work_id]))
    deferrable_unique(:work_notes, ~w(work_id position))

    create table(:work_related_urls, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:position, :integer, null: false)
      add(:url, :text, null: false)
      add(:label_id, :text, null: false)
      add(:label_scheme, :text, generated: "ALWAYS AS ('related_url') STORED")
    end

    coded_fk(:work_related_urls, :label)
    create(index(:work_related_urls, [:work_id]))
    deferrable_unique(:work_related_urls, ~w(work_id position))

    # Top-level coded columns (converted to text ids earlier) get the same
    # integrity guarantee
    top_level_coded_fk(:works, :visibility, "visibility")
    top_level_coded_fk(:works, :work_type, "work_type")
    top_level_coded_fk(:works, :behavior, "behavior")
    top_level_coded_fk(:collections, :visibility, "visibility")
    top_level_coded_fk(:file_sets, :role, "file_set_role")
  end

  defp role_scheme_expression do
    "CASE field WHEN 'contributor' THEN 'marc_relator' WHEN 'subject' THEN 'subject_role' END"
  end

  defp coded_fk(table, column) do
    execute("""
    ALTER TABLE #{table}
      ADD CONSTRAINT #{table}_#{column}_fkey
      FOREIGN KEY (#{column}_id, #{column}_scheme) REFERENCES coded_terms (id, scheme)
    """)
  end

  defp top_level_coded_fk(table, column, scheme) do
    alter table(table) do
      add(:"#{column}_scheme", :text, generated: "ALWAYS AS ('#{scheme}') STORED")
    end

    execute("""
    ALTER TABLE #{table}
      ADD CONSTRAINT #{table}_#{column}_fkey
      FOREIGN KEY (#{column}, #{column}_scheme) REFERENCES coded_terms (id, scheme)
    """)
  end

  # Positions are rewritten in one transaction when a list is reordered, so the
  # uniqueness check must wait until commit
  defp deferrable_unique(table, columns) do
    execute("""
    ALTER TABLE #{table}
      ADD CONSTRAINT #{table}_#{Enum.join(columns, "_")}_unique
      UNIQUE (#{Enum.join(columns, ", ")}) DEFERRABLE INITIALLY DEFERRED
    """)
  end

  # ---------------------------------------------------------------------------
  # integrity preflight: fail loudly before touching data

  defp preflight! do
    checks = [
      {"descriptive license ids unknown to coded_terms",
       coded_check("works", "descriptive_metadata->'license'->>'id'", "license")},
      {"descriptive rights_statement ids unknown to coded_terms",
       coded_check("works", "descriptive_metadata->'rights_statement'->>'id'", "rights_statement")},
      {"administrative library_unit ids unknown to coded_terms",
       coded_check("works", "administrative_metadata->'library_unit'->>'id'", "library_unit")},
      {"administrative preservation_level ids unknown to coded_terms",
       coded_check(
         "works",
         "administrative_metadata->'preservation_level'->>'id'",
         "preservation_level"
       )},
      {"administrative status ids unknown to coded_terms",
       coded_check("works", "administrative_metadata->'status'->>'id'", "status")},
      {"works.visibility ids unknown to coded_terms",
       coded_check("works", "visibility", "visibility")},
      {"works.work_type ids unknown to coded_terms",
       coded_check("works", "work_type", "work_type")},
      {"works.behavior ids unknown to coded_terms", coded_check("works", "behavior", "behavior")},
      {"collections.visibility ids unknown to coded_terms",
       coded_check("collections", "visibility", "visibility")},
      {"file_sets.role ids unknown to coded_terms",
       coded_check("file_sets", "role", "file_set_role")},
      {"notes with a missing note text or an unknown note type",
       """
       SELECT count(*) FROM works w
       CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->'notes'")}) e
       WHERE e->>'note' IS NULL
          OR NOT EXISTS (SELECT 1 FROM coded_terms ct WHERE ct.id = e->'type'->>'id' AND ct.scheme = 'note_type')
       """},
      {"related urls with a missing url or an unknown label",
       """
       SELECT count(*) FROM works w
       CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->'related_url'")}) e
       WHERE e->>'url' IS NULL
          OR NOT EXISTS (SELECT 1 FROM coded_terms ct WHERE ct.id = e->'label'->>'id' AND ct.scheme = 'related_url')
       """},
      {"controlled entries with an unknown role",
       """
       SELECT count(*) FROM works w
       CROSS JOIN unnest(ARRAY[#{quoted_list(@controlled_fields)}]) f(field)
       CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->f.field")}) e
       WHERE e->'role'->>'id' IS NOT NULL
         AND NOT EXISTS (
           SELECT 1 FROM coded_terms ct
           WHERE ct.id = e->'role'->>'id'
             AND ct.scheme = COALESCE(e->'role'->>'scheme', CASE f.field WHEN 'contributor' THEN 'marc_relator' WHEN 'subject' THEN 'subject_role' END)
         )
       """},
      # `role_scheme` is now derived from the field, so a role on any other
      # field has nowhere to live
      {"controlled entries carrying a role on a field that has no role scheme",
       """
       SELECT count(*) FROM works w
       CROSS JOIN unnest(ARRAY[#{quoted_list(@controlled_fields -- @role_fields)}]) f(field)
       CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->f.field")}) e
       WHERE e->'role'->>'id' IS NOT NULL
       """},
      # The natural key is now unique, so exact duplicates would fail the load
      {"works with duplicate controlled entries in one field",
       """
       SELECT COALESCE(sum(duplicates), 0) FROM (
         SELECT count(*) - count(DISTINCT (term, role)) AS duplicates
         FROM (
           SELECT w.id AS work_id, f.field,
                  CASE WHEN jsonb_typeof(e->'term') = 'object' THEN e->'term'->>'id' ELSE e->>'term' END AS term,
                  COALESCE(e->'role'->>'id', '') AS role
           FROM works w
           CROSS JOIN unnest(ARRAY[#{quoted_list(@controlled_fields)}]) f(field)
           CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->f.field")}) e
         ) entries
         WHERE term IS NOT NULL
         GROUP BY work_id, field
       ) counts
       """}
    ]

    problems =
      checks
      |> Enum.map(fn {label, sql} -> {label, count!(sql)} end)
      |> Enum.reject(fn {_label, count} -> count == 0 end)

    unless problems == [] do
      details = Enum.map_join(problems, "\n", fn {label, count} -> "  * #{count} #{label}" end)

      raise """
      Cannot migrate work metadata to relational tables until these data problems are fixed:
      #{details}
      """
    end
  end

  defp coded_check(table, expr, scheme) do
    """
    SELECT count(*) FROM #{table} t
    WHERE (#{expr}) IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM coded_terms ct WHERE ct.id = (#{expr}) AND ct.scheme = '#{scheme}')
    """
  end

  # ---------------------------------------------------------------------------
  # backfill

  defp backfill do
    Logger.info("Backfilling work_descriptive_metadata")

    execute("""
    INSERT INTO work_descriptive_metadata
      (work_id, #{Enum.join(@descriptive_values, ", ")}, title, terms_of_use, date_created,
       nav_place, license_id, rights_statement_id, inserted_at, updated_at)
    SELECT w.id,
           #{value_arrays("descriptive_metadata", @descriptive_values)},
           w.descriptive_metadata->>'title',
           w.descriptive_metadata->>'terms_of_use',
           #{edtf_array("w.descriptive_metadata->'date_created'")},
           #{nav_place_jsonb("w.descriptive_metadata->'nav_place'")},
           w.descriptive_metadata->'license'->>'id',
           w.descriptive_metadata->'rights_statement'->>'id',
           COALESCE((w.descriptive_metadata->>'inserted_at')::timestamp, w.inserted_at),
           COALESCE((w.descriptive_metadata->>'updated_at')::timestamp, w.updated_at)
    FROM works w
    """)

    Logger.info("Backfilling work_administrative_metadata")

    execute("""
    INSERT INTO work_administrative_metadata
      (work_id, #{Enum.join(@administrative_values, ", ")}, library_unit_id,
       preservation_level_id, status_id, project_cycle, inserted_at, updated_at)
    SELECT w.id,
           #{value_arrays("administrative_metadata", @administrative_values)},
           w.administrative_metadata->'library_unit'->>'id',
           w.administrative_metadata->'preservation_level'->>'id',
           w.administrative_metadata->'status'->>'id',
           w.administrative_metadata->>'project_cycle',
           COALESCE((w.administrative_metadata->>'inserted_at')::timestamp, w.inserted_at),
           COALESCE((w.administrative_metadata->>'updated_at')::timestamp, w.updated_at)
    FROM works w
    """)

    Logger.info("Backfilling work_controlled_entries")

    execute("""
    INSERT INTO work_controlled_entries (work_id, field, position, term_id, role_id)
    SELECT w.id, f.field, e.ordinality - 1,
           CASE WHEN jsonb_typeof(e.elem->'term') = 'object' THEN e.elem->'term'->>'id' ELSE e.elem->>'term' END,
           e.elem->'role'->>'id'
    FROM works w
    CROSS JOIN unnest(ARRAY[#{quoted_list(@controlled_fields)}]) f(field)
    CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->f.field")}) WITH ORDINALITY e(elem, ordinality)
    WHERE (CASE WHEN jsonb_typeof(e.elem->'term') = 'object' THEN e.elem->'term'->>'id' ELSE e.elem->>'term' END) IS NOT NULL
    """)

    Logger.info("Backfilling work_notes")

    execute("""
    INSERT INTO work_notes (work_id, position, note, type_id)
    SELECT w.id, e.ordinality - 1, e.elem->>'note', e.elem->'type'->>'id'
    FROM works w
    CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->'notes'")}) WITH ORDINALITY e(elem, ordinality)
    """)

    Logger.info("Backfilling work_related_urls")

    execute("""
    INSERT INTO work_related_urls (work_id, position, url, label_id)
    SELECT w.id, e.ordinality - 1, e.elem->>'url', e.elem->'label'->>'id'
    FROM works w
    CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->'related_url'")}) WITH ORDINALITY e(elem, ordinality)
    """)
  end

  defp verify! do
    work_count = count!("SELECT count(*) FROM works")
    descriptive_count = count!("SELECT count(*) FROM work_descriptive_metadata")
    administrative_count = count!("SELECT count(*) FROM work_administrative_metadata")

    unless work_count == descriptive_count and work_count == administrative_count do
      raise "Metadata row counts do not match works: #{work_count} works, #{descriptive_count} descriptive, #{administrative_count} administrative"
    end

    # Both sides count non-null jsonb elements the same way the backfill does,
    # so a mismatch means an array expression dropped something
    expected_values =
      count!(jsonb_element_count("descriptive_metadata", @descriptive_values)) +
        count!(jsonb_element_count("administrative_metadata", @administrative_values))

    actual_values =
      count!(array_element_count("work_descriptive_metadata", @descriptive_values)) +
        count!(array_element_count("work_administrative_metadata", @administrative_values))

    unless expected_values == actual_values do
      raise "Expected #{expected_values} metadata values, backfilled #{actual_values}"
    end

    Logger.info(
      "Backfilled #{descriptive_count} works, #{actual_values} values, " <>
        "#{count!("SELECT count(*) FROM work_controlled_entries")} controlled entries, " <>
        "#{count!("SELECT count(*) FROM work_notes")} notes, " <>
        "#{count!("SELECT count(*) FROM work_related_urls")} related urls"
    )
  end

  defp drop_legacy_objects do
    execute("DROP TRIGGER IF EXISTS trg_work_terms_ins ON works")
    execute("DROP TRIGGER IF EXISTS trg_work_terms_upd ON works")
    execute("DROP TRIGGER IF EXISTS trg_work_terms_del ON works")
    execute("DROP FUNCTION IF EXISTS refresh_work_terms_ins()")
    execute("DROP FUNCTION IF EXISTS refresh_work_terms_upd()")
    execute("DROP FUNCTION IF EXISTS refresh_work_terms_del()")
    execute("DROP TABLE IF EXISTS work_terms")
    execute("DROP FUNCTION IF EXISTS replace_controlled_value(jsonb, text, jsonb, jsonb)")
    execute("DROP FUNCTION IF EXISTS merge_jsonb_values(jsonb, jsonb, text)")
  end

  # ---------------------------------------------------------------------------
  # helpers

  defp value_arrays(column, fields) do
    Enum.map_join(fields, ",\n           ", fn field ->
      text_array("w.#{column}->'#{field}'")
    end)
  end

  # `ARRAY(subquery)` preserves the subquery's row order, and
  # `jsonb_array_elements_text` yields elements in array order. Literal JSON
  # nulls become SQL NULL and are dropped, matching what the jsonb embeds
  # treated as absent.
  defp text_array(expr) do
    "COALESCE(ARRAY(SELECT v FROM jsonb_array_elements_text(#{array_or_empty(expr)}) v WHERE v IS NOT NULL), '{}')"
  end

  # Only the EDTF string is stored; `humanized` is derived on load
  defp edtf_array(expr) do
    "COALESCE(ARRAY(SELECT e->>'edtf' FROM jsonb_array_elements(#{array_or_empty(expr)}) e WHERE e->>'edtf' IS NOT NULL), '{}')"
  end

  # The concise public map becomes the embedded schema's field names
  defp nav_place_jsonb(expr) do
    """
    COALESCE((
      SELECT jsonb_agg(
               jsonb_build_object(
                 'place_id', e->>'id',
                 'label', e->>'label',
                 'summary', e->>'summary',
                 'longitude', (e->'coordinates'->>0)::float,
                 'latitude', (e->'coordinates'->>1)::float
               ) ORDER BY ord
             )
      FROM jsonb_array_elements(#{array_or_empty(expr)}) WITH ORDINALITY t(e, ord)
    ), '[]'::jsonb)
    """
  end

  defp jsonb_element_count(column, fields) do
    """
    SELECT count(*)
    FROM works w
    CROSS JOIN unnest(ARRAY[#{quoted_list(fields)}]) f(field)
    CROSS JOIN LATERAL jsonb_array_elements_text(#{array_or_empty("w.#{column}->f.field")}) e(value)
    WHERE e.value IS NOT NULL
    """
  end

  defp array_element_count(table, fields) do
    sums = Enum.map_join(fields, " + ", &"COALESCE(array_length(#{&1}, 1), 0)")
    "SELECT COALESCE(sum(#{sums}), 0) FROM #{table}"
  end

  defp array_or_empty(expr),
    do: "CASE WHEN jsonb_typeof(#{expr}) = 'array' THEN #{expr} ELSE '[]'::jsonb END"

  defp quoted_list(values), do: Enum.map_join(values, ", ", &"'#{&1}'")

  defp count!(sql) do
    %{rows: [[count]]} = repo().query!(sql)
    to_integer(count)
  end

  # `sum()` over bigint returns numeric, which arrives as a Decimal; comparing
  # that to 0 with `==` is always false, so normalize before any check does
  defp to_integer(nil), do: 0
  defp to_integer(count) when is_integer(count), do: count
  defp to_integer(%Decimal{} = count), do: Decimal.to_integer(count)
end
