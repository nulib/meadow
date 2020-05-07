defmodule Meadow.Repo.Migrations.CreateCodedTerms do
  use Ecto.Migration

  def change do
    create table(:coded_terms, primary_key: false) do
      add :scheme, :string, primary_key: true
      add :id, :string, primary_key: true
      add :label, :string

      timestamps()
    end
  end
end
