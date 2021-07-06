defmodule Meadow.Repo.Migrations.AddExtractedMetadataToFileSets do
  use Ecto.Migration

  import Meadow.Utils.DependencyTriggers.ForEachRow

  def up do
    disable_parent_trigger(:works, :file_sets)
    rename table("file_sets"), :metadata, to: :core_metadata
    alter table("file_sets"), do: add :extracted_metadata, :map, default: %{}
    execute """
    UPDATE file_sets
    SET extracted_metadata = core_metadata -> 'extracted_metadata',
        core_metadata = core_metadata - 'extracted_metadata';
    """
    enable_parent_trigger(:works, :file_sets)
  end

  def down do
    disable_parent_trigger(:works, :file_sets)
    execute """
    UPDATE file_sets
    SET core_metadata = jsonb_set(core_metadata, '{extracted_metadata}', extracted_metadata);
    """
    alter table("file_sets"), do: remove :extracted_metadata
    rename table("file_sets"), :core_metadata, to: :metadata
    enable_parent_trigger(:works, :file_sets)
  end
end
