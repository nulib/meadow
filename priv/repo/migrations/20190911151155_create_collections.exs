defmodule Meadow.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table("collections") do
      add(:name, :string)
      add(:description, :string)
      add(:keywords, {:array, :string}, default: [])
      add(:finding_aid_url, :text)
      add(:admin_email, :text)
      add(:featured, :boolean)
      add(:published, :boolean)
      add(:visibility, :map)
      timestamps()
    end

    create(unique_index(:collections, [:name]))
  end
end
