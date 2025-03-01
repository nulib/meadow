defmodule Meadow.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add(:title, :string)
      add(:description, :text)
      add(:keywords, {:array, :string}, default: [])
      add(:finding_aid_url, :text)
      add(:admin_email, :text)
      add(:featured, :boolean, null: false, default: false)
      add(:published, :boolean)
      add(:visibility, :map)
      timestamps()
    end

    create(unique_index(:collections, [:title]))
  end
end
