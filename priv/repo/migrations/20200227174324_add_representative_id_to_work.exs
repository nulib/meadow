defmodule Meadow.Repo.Migrations.AddRepresentativeIdToWork do
  use Ecto.Migration

  def change do
    alter table("works") do
      add(:representative_file_set_id, references("file_sets", on_delete: :nilify_all))
    end
  end
end
