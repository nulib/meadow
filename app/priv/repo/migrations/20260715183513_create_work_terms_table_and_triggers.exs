defmodule Meadow.Repo.Migrations.CreateWorkTermsTableAndTriggers do
  use Ecto.Migration

  require Logger

  def up do
    create table(:work_terms, primary_key: false) do
      add(:work_id, :uuid, null: false)
      add(:field_name, :text, null: false)
      add(:term, :text)
    end
    create index(:work_terms, [:term])
    create index(:work_terms, [:work_id])

    # Create triggers to keep the work_terms table in sync with the works table
    execute("""
      CREATE OR REPLACE FUNCTION refresh_work_terms_ins() RETURNS trigger AS $$
      BEGIN
        DELETE FROM work_terms wt
        USING new_table n
        WHERE wt.work_id = n.id;

        INSERT INTO work_terms (work_id, field_name, term)
        SELECT
          n.id,
          f.key,
          CASE
            WHEN jsonb_typeof(elem->'term') = 'object' THEN elem->'term'->>'id'
            ELSE elem->>'term'
          END
        FROM new_table n
        CROSS JOIN LATERAL jsonb_each(n.descriptive_metadata) AS f(key, value)
        CROSS JOIN LATERAL jsonb_array_elements(
          CASE WHEN jsonb_typeof(f.value) = 'array' THEN f.value ELSE '[]'::jsonb END
        ) AS elem
        WHERE elem ? 'term';

        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    """)

    execute("""
      CREATE TRIGGER trg_work_terms_ins
      AFTER INSERT ON works
      REFERENCING NEW TABLE AS new_table
      FOR EACH STATEMENT EXECUTE FUNCTION refresh_work_terms_ins();
    """)

    execute("""
      CREATE OR REPLACE FUNCTION refresh_work_terms_upd() RETURNS trigger AS $$
      BEGIN
        DELETE FROM work_terms wt
        USING new_table n
        WHERE wt.work_id = n.id;

        INSERT INTO work_terms (work_id, field_name, term)
        SELECT
          n.id,
          f.key,
          CASE
            WHEN jsonb_typeof(elem->'term') = 'object' THEN elem->'term'->>'id'
            ELSE elem->>'term'
          END
        FROM new_table n
        CROSS JOIN LATERAL jsonb_each(n.descriptive_metadata) AS f(key, value)
        CROSS JOIN LATERAL jsonb_array_elements(
          CASE WHEN jsonb_typeof(f.value) = 'array' THEN f.value ELSE '[]'::jsonb END
        ) AS elem
        WHERE elem ? 'term';

        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    """)

    execute("""
      CREATE TRIGGER trg_work_terms_upd
      AFTER UPDATE ON works
      REFERENCING NEW TABLE AS new_table
      FOR EACH STATEMENT EXECUTE FUNCTION refresh_work_terms_upd();
    """)

    execute("""
      CREATE OR REPLACE FUNCTION refresh_work_terms_del() RETURNS trigger AS $$
      BEGIN
        DELETE FROM work_terms wt
        USING old_table o
        WHERE wt.work_id = o.id;

        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    """)

    execute("""
      CREATE TRIGGER trg_work_terms_del
      AFTER DELETE ON works
      REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT EXECUTE FUNCTION refresh_work_terms_del();
    """)

  Logger.info("Populating work_terms table with existing data...")
  execute("""
    INSERT INTO work_terms (work_id, field_name, term)
    SELECT
      w.id,
      f.key,
      CASE
        WHEN jsonb_typeof(elem->'term') = 'object' THEN elem->'term'->>'id'
        ELSE elem->>'term'
      END
    FROM works w
    CROSS JOIN LATERAL jsonb_each(w.descriptive_metadata) AS f(key, value)
    CROSS JOIN LATERAL jsonb_array_elements(
      CASE WHEN jsonb_typeof(f.value) = 'array' THEN f.value ELSE '[]'::jsonb END
    ) AS elem
    WHERE elem ? 'term';
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS trg_work_terms_ins ON works;")
    execute("DROP TRIGGER IF EXISTS trg_work_terms_upd ON works;")
    execute("DROP TRIGGER IF EXISTS trg_work_terms_del ON works;")
    execute("DROP FUNCTION IF EXISTS refresh_work_terms_ins();")
    execute("DROP FUNCTION IF EXISTS refresh_work_terms_upd();")
    execute("DROP FUNCTION IF EXISTS refresh_work_terms_del();")
    drop table(:work_terms)
  end
end
