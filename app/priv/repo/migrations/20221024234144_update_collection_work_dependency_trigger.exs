defmodule Meadow.Repo.Migrations.UpdateCollectionWorkDependencyTrigger do
  use Ecto.Migration

  import Meadow.Utils.DependencyTriggers

  def up do
    drop_dependency_trigger(:collections, :works)
    create_dependency_trigger(:collections, :works, [:title, :description])
  end

  def down do
    drop_dependency_trigger(:collections, :works)
    create_dependency_trigger(:collections, :works, [:title])
  end
end
