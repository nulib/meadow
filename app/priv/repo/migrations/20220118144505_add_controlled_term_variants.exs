defmodule Meadow.Repo.Migrations.AddControlledTermVariants do
  use Ecto.Migration

  def change do
    alter table("controlled_term_cache") do
      add(:variants, {:array, :string}, default: [])
    end
  end
end
