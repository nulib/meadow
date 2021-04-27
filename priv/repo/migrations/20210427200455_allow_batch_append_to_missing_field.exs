defmodule Meadow.Repo.Migrations.AllowBatchAppendToMissingField do
  use Ecto.Migration

  def up do
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
            new_value = result->key || value;
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
end
