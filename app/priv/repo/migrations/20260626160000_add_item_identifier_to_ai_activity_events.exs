defmodule Meadow.Repo.Migrations.AddItemIdentifierToAiActivityEvents do
  use Ecto.Migration

  # Per-item human attestation: a `human_attested` event can name the individual
  # item of a multivalued field it attests (a controlled-term id, a plain string,
  # etc.). NULL means the event applies to the whole field, the existing behavior.
  def change do
    alter table(:ai_activity_events) do
      add(:item_identifier, :string)
    end

    create(index(:ai_activity_events, [:item_identifier]))
  end
end
