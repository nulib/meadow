defmodule Meadow.Repo.Migrations.CreateAIProvenance do
  use Ecto.Migration

  def change do
    create table(:ai_activities, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:activity_type, :string, null: false)
      add(:system_name, :string)
      add(:system_version, :string)
      add(:model, :string)
      add(:prompt_version, :string)
      add(:prompt_text, :text)
      add(:prompt_hash, :string)
      add(:input, :jsonb)
      add(:output, :jsonb)
      add(:output_hash, :string)
      add(:cost_usd, :float)
      add(:started_at, :utc_datetime_usec)
      add(:completed_at, :utc_datetime_usec)
      add(:initiated_by, :string)
      add(:user_category, :string)
      add(:retention_policy, :string)
      add(:ai_use_type, :string)
      add(:access_mode, :string)
      add(:reversibility, :string)
      add(:model_provider, :string)
      add(:model_version, :string)
      add(:model_type, :string)
      add(:c2pa_manifest_id, :text)
      add(:c2pa_claim_id, :text)
      add(:c2pa_validation_status, :string)
      add(:c2pa_signature_status, :string)
      add(:status, :string, null: false, default: "pending")
      add(:error, :text)

      add(:work_id, :uuid)
      add(:file_set_id, :uuid)
      add(:plan_id, references(:plans, type: :uuid, on_delete: :nilify_all))
      add(:plan_change_id, references(:plan_changes, type: :uuid, on_delete: :nilify_all))

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_activities, [:activity_type]))
    create(index(:ai_activities, [:ai_use_type]))
    create(index(:ai_activities, [:access_mode]))
    create(index(:ai_activities, [:reversibility]))
    create(index(:ai_activities, [:status]))
    create(index(:ai_activities, [:work_id]))
    create(index(:ai_activities, [:file_set_id]))
    create(index(:ai_activities, [:plan_id]))
    create(index(:ai_activities, [:plan_change_id]))
    create(index(:ai_activities, [:inserted_at]))

    create table(:ai_activity_sources, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:activity_id, references(:ai_activities, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:collection_id, :uuid)
      add(:collection_title, :string)
      add(:item_id, :string)
      add(:item_type, :string)
      add(:work_id, :uuid)
      add(:file_set_id, :uuid)
      add(:pointer, :jsonb)
      add(:holding_organization, :string)
      add(:access_link, :text)
      add(:restricted, :boolean, default: false, null: false)
      add(:source_snapshot, :jsonb)
      add(:premis_object_category, :string)
      add(:object_identifier_type, :string)
      add(:object_identifier_value, :text)
      add(:content_hash, :string)
      add(:content_hash_algorithm, :string)
      add(:relationship_role, :string)
      add(:ingredient_relationship, :string)
      add(:c2pa_manifest_id, :text)
      add(:c2pa_claim_id, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_activity_sources, [:activity_id]))
    create(index(:ai_activity_sources, [:work_id]))
    create(index(:ai_activity_sources, [:file_set_id]))

    create table(:ai_activity_targets, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:activity_id, references(:ai_activities, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:target_type, :string, null: false)
      add(:target_id, :string, null: false)
      add(:field_path, :string, null: false)
      add(:operation, :string)
      add(:source_value_snapshot, :jsonb)
      add(:proposed_value, :jsonb)
      add(:origin, :string, null: false)
      add(:status, :string, null: false, default: "proposed")
      add(:premis_object_category, :string)
      add(:object_identifier_type, :string)
      add(:object_identifier_value, :text)
      add(:access_link, :text)
      add(:restricted, :boolean, default: false, null: false)
      add(:content_hash, :string)
      add(:content_hash_algorithm, :string)
      add(:c2pa_action, :string)
      add(:digital_source_type_uri, :text)
      add(:ingredient_relationship, :string)
      add(:human_oversight_level, :string)
      add(:c2pa_assertion_label, :string)
      add(:c2pa_manifest_id, :text)
      add(:c2pa_claim_id, :text)
      add(:c2pa_validation_status, :string)
      add(:c2pa_signature_status, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_activity_targets, [:activity_id]))
    create(index(:ai_activity_targets, [:target_type, :target_id]))
    create(index(:ai_activity_targets, [:field_path]))
    create(index(:ai_activity_targets, [:origin]))
    create(index(:ai_activity_targets, [:status]))
    create(index(:ai_activity_targets, [:c2pa_action]))

    create table(:ai_activity_events, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :activity_target_id,
        references(:ai_activity_targets, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:event_type, :string, null: false)
      add(:actor, :string)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:value_before, :jsonb)
      add(:value_after, :jsonb)
      add(:notes, :text)
      add(:premis_event_type, :string)
      add(:outcome, :string)
      add(:outcome_detail, :text)
      add(:c2pa_action, :string)
      add(:c2pa_assertion_label, :string)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_activity_events, [:activity_target_id]))
    create(index(:ai_activity_events, [:event_type]))
    create(index(:ai_activity_events, [:premis_event_type]))
    create(index(:ai_activity_events, [:occurred_at]))

    create table(:ai_agents, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:agent_type, :string, null: false)
      add(:name, :string, null: false)
      add(:identifier_type, :string)
      add(:identifier_value, :text)
      add(:version, :string)
      add(:metadata, :jsonb)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_agents, [:agent_type]))
    create(index(:ai_agents, [:identifier_type, :identifier_value]))

    create table(:ai_activity_event_agents, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:activity_event_id, references(:ai_activity_events, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:agent_id, references(:ai_agents, type: :uuid, on_delete: :delete_all), null: false)
      add(:role, :string, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_activity_event_agents, [:activity_event_id]))
    create(index(:ai_activity_event_agents, [:agent_id]))
    create(unique_index(:ai_activity_event_agents, [:activity_event_id, :agent_id, :role]))

    alter table(:plan_changes) do
      add(:ai_activity_id, references(:ai_activities, type: :uuid, on_delete: :nilify_all))
    end

    create(index(:plan_changes, [:ai_activity_id]))

    alter table(:file_set_annotations) do
      add(:ai_activity_id, references(:ai_activities, type: :uuid, on_delete: :nilify_all))
    end

    create(index(:file_set_annotations, [:ai_activity_id]))
  end
end
