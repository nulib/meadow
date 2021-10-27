defmodule Meadow.Repo.Migrations.CreateBatches do
  use Ecto.Migration

  def change do
    create table(:batches) do
      add(:nickname, :string)
      add(:user, :string)
      add(:type, :string)
      add(:status, :string)
      add(:query, :text)
      add(:add, :text)
      add(:delete, :text)
      add(:replace, :text)
      add(:error, :string)
      add(:started, :utc_datetime_usec)
      add(:works_updated, :integer)
      add(:active, :boolean)
      timestamps()
    end

    create(unique_index(:batches, [:active], where: "active=true"))
  end
end
