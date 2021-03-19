defmodule Meadow.Repo.Migrations.ChangeUndelabelinedToUndetermined do
  use Ecto.Migration
  alias Meadow.Repo

  @id "http://rightsstatements.org/vocab/UND/1.0/"
  @scheme "rights_statement"
  @wrong "Copyright Undelabelined"
  @right "Copyright Undetermined"
  @coded_term_sql "UPDATE coded_terms SET label = $1 WHERE scheme = $2 AND id = $3"
  @works_sql """
    UPDATE works
    SET descriptive_metadata = jsonb_set(descriptive_metadata, '{rights_statement,label}', $1)
    WHERE descriptive_metadata->'rights_statement'->>'id' = $2
  """

  def up do
    update_coded_term(@right)
    update_existing_work_labels(@right)
  end

  def down do
    update_coded_term(@wrong)
    update_existing_work_labels(@wrong)
  end

  defp update_coded_term(value) do
    Repo.query!(@coded_term_sql, [value, @scheme, @id])
  end

  defp update_existing_work_labels(value) do
    Repo.query!(@works_sql, [value, @id])
  end
end
