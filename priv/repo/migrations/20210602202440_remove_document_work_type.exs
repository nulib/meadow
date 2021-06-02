defmodule Meadow.Repo.Migrations.RemoveDocumentWorkType do
  use Ecto.Migration

  def up do
    execute """
    DELETE FROM coded_terms
    WHERE scheme = 'work_type' AND id = 'DOCUMENT';
    """
  end

  def down do
    execute """
    INSERT INTO coded_terms (id, scheme, label, inserted_at, updated_at)
    VALUES ('DOCUMENT', 'work_type', 'Document', now(), now())
    """
  end
end
