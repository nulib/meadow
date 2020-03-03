defmodule Meadow.Repo.Migrations.ChangeCollectionsTableAddRepresentativeWork do
  use Ecto.Migration

  def change do
    alter table("collections") do
      add :representative_work_id, references("works", on_delete: :nilify_all)
    end
  end
end
