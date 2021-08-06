defmodule Meadow.Repo.Migrations.AddDerivativesToFileSetsParentTrigger do
  use Ecto.Migration

  alias Meadow.Utils.DependencyTriggers.ForEachStatement, as: StatementTriggers

  def up do
    StatementTriggers.drop_parent_trigger(:works, :file_sets)
    StatementTriggers.create_parent_trigger(:works, :file_sets, [:core_metadata, :derivatives, :rank])
  end

  def down do
    StatementTriggers.drop_parent_trigger(:works, :file_sets)
    StatementTriggers.create_parent_trigger(:works, :file_sets, [:core_metadata, :rank])
  end
end
