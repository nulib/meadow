defmodule Meadow.Repo.Migrations.CreateWorkMetadataTables do
  @moduledoc """
  Move work descriptive/administrative metadata out of the `works` jsonb
  columns into relational tables:

    * `work_descriptive_metadata`, `work_administrative_metadata` (one row per work)
    * `work_metadata_values` (repeating free text, all fields)
    * `work_controlled_entries` (controlled terms with optional role)
    * `work_notes`, `work_related_urls`, `work_dates_created`, `work_nav_places`

  Existing data is backfilled from the jsonb columns, which are left in place
  (unused) until the cleanup migration drops them. The `work_terms` projection
  table and the jsonb batch-update functions are replaced by the new tables
  and dropped here. Forward-only for data: `down/0` drops the new tables, the
  jsonb columns still hold the original data.
  """

  use Ecto.Migration

  require Logger

  @descriptive_values ~w(abstract alternate_title box_name box_number caption catalog_key citation
    cultural_context description folder_name folder_number identifier keywords legacy_identifier
    physical_description_material physical_description_size provenance publisher related_material
    rights_holder scope_and_contents series source table_of_contents)

  @administrative_values ~w(project_name project_desc project_proposer project_manager project_task_number)

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)

  @metadata_tables ~w(work_descriptive_metadata work_administrative_metadata work_metadata_values
    work_controlled_entries work_notes work_related_urls work_dates_created work_nav_places)

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
      add(:title, :text)
      add(:terms_of_use, :text)
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

    create table(:work_metadata_values, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:section, :text, null: false)
      add(:field, :text, null: false)
      add(:position, :integer, null: false)
      add(:value, :text, null: false)
    end

    create(
      constraint(:work_metadata_values, :section_must_be_known,
        check: "section IN ('descriptive', 'administrative')"
      )
    )

    create(index(:work_metadata_values, [:work_id, :section, :field]))
    create(index(:work_metadata_values, [:field, :value]))
    deferrable_unique(:work_metadata_values, ~w(work_id section field position))

    create table(:work_controlled_entries, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:field, :text, null: false)
      add(:position, :integer, null: false)
      add(:term_id, :text, null: false)
      add(:role_id, :text)
      add(:role_scheme, :text)
    end

    create(
      constraint(:work_controlled_entries, :field_must_be_known,
        check: "field IN (#{quoted_list(@controlled_fields)})"
      )
    )

    create(
      constraint(:work_controlled_entries, :role_scheme_must_be_a_role_scheme,
        check: "role_scheme IS NULL OR role_scheme IN ('marc_relator', 'subject_role')"
      )
    )

    create(
      constraint(:work_controlled_entries, :role_id_and_scheme_go_together,
        check: "(role_id IS NULL) = (role_scheme IS NULL)"
      )
    )

    execute("""
    ALTER TABLE work_controlled_entries
      ADD CONSTRAINT work_controlled_entries_role_fkey
      FOREIGN KEY (role_id, role_scheme) REFERENCES coded_terms (id, scheme)
    """)

    create(index(:work_controlled_entries, [:work_id, :field]))
    create(index(:work_controlled_entries, [:term_id]))
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

    create table(:work_dates_created, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:position, :integer, null: false)
      add(:edtf, :text, null: false)
      add(:humanized, :text)
    end

    create(index(:work_dates_created, [:work_id]))
    create(index(:work_dates_created, [:edtf]))
    deferrable_unique(:work_dates_created, ~w(work_id position))

    create table(:work_nav_places, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:work_id, references(:works, type: :uuid, on_delete: :delete_all), null: false)
      add(:position, :integer, null: false)
      add(:place_id, :text)
      add(:label, :text)
      add(:summary, :text)
      add(:longitude, :float)
      add(:latitude, :float)
    end

    create(index(:work_nav_places, [:work_id]))
    create(index(:work_nav_places, [:place_id]))
    deferrable_unique(:work_nav_places, ~w(work_id position))

    # Top-level coded columns (converted to text ids earlier) get the same
    # integrity guarantee
    top_level_coded_fk(:works, :visibility, "visibility")
    top_level_coded_fk(:works, :work_type, "work_type")
    top_level_coded_fk(:works, :behavior, "behavior")
    top_level_coded_fk(:collections, :visibility, "visibility")
    top_level_coded_fk(:file_sets, :role, "file_set_role")
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
    INSERT INTO work_descriptive_metadata (work_id, title, terms_of_use, license_id, rights_statement_id, inserted_at, updated_at)
    SELECT w.id,
           w.descriptive_metadata->>'title',
           w.descriptive_metadata->>'terms_of_use',
           w.descriptive_metadata->'license'->>'id',
           w.descriptive_metadata->'rights_statement'->>'id',
           COALESCE((w.descriptive_metadata->>'inserted_at')::timestamp, w.inserted_at),
           COALESCE((w.descriptive_metadata->>'updated_at')::timestamp, w.updated_at)
    FROM works w
    """)

    Logger.info("Backfilling work_administrative_metadata")

    execute("""
    INSERT INTO work_administrative_metadata (work_id, library_unit_id, preservation_level_id, status_id, project_cycle, inserted_at, updated_at)
    SELECT w.id,
           w.administrative_metadata->'library_unit'->>'id',
           w.administrative_metadata->'preservation_level'->>'id',
           w.administrative_metadata->'status'->>'id',
           w.administrative_metadata->>'project_cycle',
           COALESCE((w.administrative_metadata->>'inserted_at')::timestamp, w.inserted_at),
           COALESCE((w.administrative_metadata->>'updated_at')::timestamp, w.updated_at)
    FROM works w
    """)

    Logger.info("Backfilling work_metadata_values")
    backfill_values("descriptive", "descriptive_metadata", @descriptive_values)
    backfill_values("administrative", "administrative_metadata", @administrative_values)

    Logger.info("Backfilling work_controlled_entries")

    execute("""
    INSERT INTO work_controlled_entries (work_id, field, position, term_id, role_id, role_scheme)
    SELECT w.id, f.field, e.ordinality - 1,
           CASE WHEN jsonb_typeof(e.elem->'term') = 'object' THEN e.elem->'term'->>'id' ELSE e.elem->>'term' END,
           e.elem->'role'->>'id',
           CASE WHEN e.elem->'role'->>'id' IS NULL THEN NULL
                ELSE COALESCE(e.elem->'role'->>'scheme', CASE f.field WHEN 'contributor' THEN 'marc_relator' WHEN 'subject' THEN 'subject_role' END)
           END
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

    Logger.info("Backfilling work_dates_created")

    execute("""
    INSERT INTO work_dates_created (work_id, position, edtf, humanized)
    SELECT w.id, e.ordinality - 1, e.elem->>'edtf', e.elem->>'humanized'
    FROM works w
    CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->'date_created'")}) WITH ORDINALITY e(elem, ordinality)
    WHERE e.elem->>'edtf' IS NOT NULL
    """)

    Logger.info("Backfilling work_nav_places")

    execute("""
    INSERT INTO work_nav_places (work_id, position, place_id, label, summary, longitude, latitude)
    SELECT w.id, e.ordinality - 1, e.elem->>'id', e.elem->>'label', e.elem->>'summary',
           (e.elem->'coordinates'->>0)::float, (e.elem->'coordinates'->>1)::float
    FROM works w
    CROSS JOIN LATERAL jsonb_array_elements(#{array_or_empty("w.descriptive_metadata->'nav_place'")}) WITH ORDINALITY e(elem, ordinality)
    """)
  end

  defp backfill_values(section, column, fields) do
    execute("""
    INSERT INTO work_metadata_values (work_id, section, field, position, value)
    SELECT w.id, '#{section}', f.field, e.ordinality - 1, e.value
    FROM works w
    CROSS JOIN unnest(ARRAY[#{quoted_list(fields)}]) f(field)
    CROSS JOIN LATERAL jsonb_array_elements_text(#{array_or_empty("w.#{column}->f.field")}) WITH ORDINALITY e(value, ordinality)
    WHERE e.value IS NOT NULL
    """)
  end

  defp verify! do
    work_count = count!("SELECT count(*) FROM works")
    descriptive_count = count!("SELECT count(*) FROM work_descriptive_metadata")
    administrative_count = count!("SELECT count(*) FROM work_administrative_metadata")

    unless work_count == descriptive_count and work_count == administrative_count do
      raise "Metadata row counts do not match works: #{work_count} works, #{descriptive_count} descriptive, #{administrative_count} administrative"
    end

    expected_values =
      count!("""
      SELECT COALESCE(sum(jsonb_array_length(#{array_or_empty("w.descriptive_metadata->f.field")})), 0)
      FROM works w CROSS JOIN unnest(ARRAY[#{quoted_list(@descriptive_values)}]) f(field)
      """) +
        count!("""
        SELECT COALESCE(sum(jsonb_array_length(#{array_or_empty("w.administrative_metadata->f.field")})), 0)
        FROM works w CROSS JOIN unnest(ARRAY[#{quoted_list(@administrative_values)}]) f(field)
        """)

    actual_values = count!("SELECT count(*) FROM work_metadata_values")

    unless expected_values == actual_values do
      raise "Expected #{expected_values} metadata values, backfilled #{actual_values}"
    end

    Logger.info(
      "Backfilled #{descriptive_count} works, #{actual_values} values, " <>
        "#{count!("SELECT count(*) FROM work_controlled_entries")} controlled entries, " <>
        "#{count!("SELECT count(*) FROM work_notes")} notes, " <>
        "#{count!("SELECT count(*) FROM work_related_urls")} related urls, " <>
        "#{count!("SELECT count(*) FROM work_dates_created")} dates, " <>
        "#{count!("SELECT count(*) FROM work_nav_places")} places"
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

  defp array_or_empty(expr),
    do: "CASE WHEN jsonb_typeof(#{expr}) = 'array' THEN #{expr} ELSE '[]'::jsonb END"

  defp quoted_list(values), do: Enum.map_join(values, ", ", &"'#{&1}'")

  defp count!(sql) do
    %{rows: [[count]]} = repo().query!(sql)
    count || 0
  end
end
