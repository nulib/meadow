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
    CREATE OR REPLACE FUNCTION replace_uncontrolled_value(metadata jsonb, field_name text, new_value jsonb)
      RETURNS jsonb
      LANGUAGE 'plpgsql'
    AS $function$
    BEGIN
      RETURN jsonb_set(metadata, ('{'||field_name||'}')::text[], new_value);
    END;
    $function$
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS replace_controlled_value;"
    execute "DROP FUNCTION IF EXISTS replace_uncontrolled_value;"
  end
end
