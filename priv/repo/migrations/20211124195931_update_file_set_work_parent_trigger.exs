defmodule Meadow.Repo.Migrations.UpdateFileSetWorkParentTrigger do
  use Ecto.Migration

  import Meadow.Utils.DependencyTriggers

  def up do
    drop_parent_trigger(:works, :file_sets)
    create_parent_trigger(:works, :file_sets, [:core_metadata, :derivatives, :poster_offset, :rank, :structural_metadata])
  end

  def down do
    drop_parent_trigger(:works, :file_sets)
    create_parent_trigger(:works, :file_sets, [:core_metadata, :derivatives, :rank])
  end
end
