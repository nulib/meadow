defmodule Meadow.Repo.Migrations.MoveArkToTopLevel do
  use Ecto.Migration

  def up do
    alter table(:works) do
      add :ark, :string
    end

    create index(:works, :ark)

    execute("ALTER PUBLICATION events DROP TABLE works")
    execute("UPDATE works SET ark = descriptive_metadata->>'ark'")

    execute(
      "UPDATE works SET descriptive_metadata = jsonb_delete_path(descriptive_metadata, '{ark}')"
    )

    execute("ALTER PUBLICATION events ADD TABLE works")
  end

  def down do
    execute("ALTER PUBLICATION events DROP TABLE works")

    execute(
      "UPDATE works SET descriptive_metadata = jsonb_set(descriptive_metadata, '{ark}', to_jsonb(ark::text))"
    )

    execute("ALTER PUBLICATION events ADD TABLE works")

    drop index(:works, [:ark])

    alter table(:works) do
      remove :ark
    end
  end
end
