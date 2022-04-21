defmodule Meadow.Repo.Migrations.CreateBatchUpdateFunctions do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION replace_controlled_value(metadata jsonb, field_name text, remove jsonb, add jsonb)
      RETURNS jsonb
      LANGUAGE 'plpgsql'
    AS $function$
    DECLARE
      existing jsonb := metadata->field_name;
      result jsonb := '[]'::jsonb;
      val jsonb;
    BEGIN
      FOR val IN SELECT * FROM jsonb_array_elements(existing) LOOP
        IF val NOT IN (SELECT * FROM jsonb_array_elements(remove)) THEN
          result = result || val;
        END IF;
      END LOOP;

      FOR val IN SELECT * FROM jsonb_array_elements(add) LOOP
        IF val NOT IN (SELECT * FROM jsonb_array_elements(existing)) THEN
          result = result || val;
        END IF;
      END LOOP;

      result = jsonb_set(metadata, ('{'||field_name||'}')::text[], result);
        RETURN result;
      END;
    $function$;
    """

    execute """
    CREATE OR REPLACE FUNCTION merge_jsonb_values(metadata jsonb, new_values jsonb, mode text)
      RETURNS jsonb
      LANGUAGE 'plpgsql'
    AS $function$
    DECLARE
      result jsonb := metadata;
      new_value jsonb;
    key text;
    value jsonb;
    BEGIN
      RAISE DEBUG '% (%)', new_values, mode;
      FOR key, value IN SELECT * FROM jsonb_each(new_values) LOOP
        CASE mode
          WHEN 'append' THEN
            IF result->key IS NULL THEN
              new_value = value;
            ELSE
              new_value = result->key || value;
            END IF;
          WHEN 'replace' THEN
            new_value = value;
          ELSE
            RAISE EXCEPTION 'Unknown merge mode: %', mode;
        END CASE;
        result = jsonb_set(result, ('{'||key||'}')::text[], new_value);
      END LOOP;
      RETURN result;
    END;
    $function$
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS merge_jsonb_values;"
    execute "DROP FUNCTION IF EXISTS replace_uncontrolled_value;"
  end
end
