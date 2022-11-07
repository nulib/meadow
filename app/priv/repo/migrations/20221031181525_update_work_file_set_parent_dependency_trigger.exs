defmodule Meadow.Repo.Migrations.UpdateWorkFileSetParentDependencyTrigger do
  use Ecto.Migration

  import Meadow.Utils.DependencyTriggers

  def up do
    drop_parent_trigger(:works, :file_sets)

    create_parent_trigger(:works, :file_sets, [
      :core_metadata,
      :derivatives,
      :extracted_metadata,
      :poster_offset,
      :rank,
      :role,
      :structural_metadata
    ])
  end

  def down do
    drop_parent_trigger(:works, :file_sets)
    create_parent_trigger(:works, :file_sets, [:core_metadata, :derivatives, :rank])
  end
end
