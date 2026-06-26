defmodule MeadowWeb.Schema.AIProvenanceTypes do
  @moduledoc "GraphQL types for AI provenance."

  use Absinthe.Schema.Notation

  alias MeadowWeb.Resolvers.AIProvenance
  alias MeadowWeb.Schema.Middleware

  object :ai_provenance_queries do
    field :ai_activity, :ai_activity do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&AIProvenance.activity/3)
    end

    field :ai_activities, list_of(:ai_activity) do
      arg(:work_id, :id)
      arg(:file_set_id, :id)
      arg(:plan_id, :id)
      arg(:plan_change_id, :id)
      arg(:activity_type, :string)
      arg(:ai_use_type, :string)
      arg(:access_mode, :string)
      arg(:status, :string)
      arg(:limit, :integer, default_value: 100)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&AIProvenance.activities/3)
    end
  end

  object :ai_activity do
    field(:id, non_null(:id))
    field(:activity_type, non_null(:string))
    field(:system_name, :string)
    field(:system_version, :string)
    field(:model, :string)
    field(:prompt_version, :string)
    field(:prompt_text, :string)
    field(:prompt_hash, :string)
    field(:input, :json)
    field(:output, :json)
    field(:output_hash, :string)
    field(:cost_usd, :float)
    field(:started_at, :datetime)
    field(:completed_at, :datetime)
    field(:initiated_by, :string)
    field(:user_category, :string)
    field(:retention_policy, :string)
    field(:ai_use_type, :string)
    field(:access_mode, :string)
    field(:reversibility, :string)
    field(:model_provider, :string)
    field(:model_version, :string)
    field(:model_type, :string)
    field(:c2pa_manifest_id, :string)
    field(:c2pa_claim_id, :string)
    field(:c2pa_validation_status, :string)
    field(:c2pa_signature_status, :string)
    field(:status, non_null(:string))
    field(:error, :string)
    field(:work_id, :id)
    field(:file_set_id, :id)
    field(:plan_id, :id)
    field(:plan_change_id, :id)
    field(:sources, list_of(:ai_activity_source))
    field(:targets, list_of(:ai_activity_target))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :ai_activity_source do
    field(:id, non_null(:id))
    field(:activity_id, non_null(:id))
    field(:collection_id, :id)
    field(:collection_title, :string)
    field(:item_id, :string)
    field(:item_type, :string)
    field(:work_id, :id)
    field(:file_set_id, :id)
    field(:pointer, :json)
    field(:holding_organization, :string)
    field(:access_link, :string)
    field(:restricted, :boolean)
    field(:source_snapshot, :json)
    field(:premis_object_category, :string)
    field(:object_identifier_type, :string)
    field(:object_identifier_value, :string)
    field(:content_hash, :string)
    field(:content_hash_algorithm, :string)
    field(:relationship_role, :string)
    field(:ingredient_relationship, :string)
    field(:c2pa_manifest_id, :string)
    field(:c2pa_claim_id, :string)
  end

  object :ai_activity_target do
    field(:id, non_null(:id))
    field(:activity_id, non_null(:id))
    field(:target_type, non_null(:string))
    field(:target_id, non_null(:string))
    field(:field_path, non_null(:string))
    field(:operation, :string)
    field(:source_value_snapshot, :json)
    field(:proposed_value, :json)
    field(:origin, non_null(:string))
    field(:status, non_null(:string))
    field(:premis_object_category, :string)
    field(:object_identifier_type, :string)
    field(:object_identifier_value, :string)
    field(:access_link, :string)
    field(:restricted, :boolean)
    field(:content_hash, :string)
    field(:content_hash_algorithm, :string)
    field(:c2pa_action, :string)
    field(:digital_source_type_uri, :string)
    field(:ingredient_relationship, :string)
    field(:human_oversight_level, :string)
    field(:c2pa_assertion_label, :string)
    field(:c2pa_manifest_id, :string)
    field(:c2pa_claim_id, :string)
    field(:c2pa_validation_status, :string)
    field(:c2pa_signature_status, :string)
    field(:events, list_of(:ai_activity_event))

    @desc "Per-item AI attribution, reconciled against the field's current value."
    field :item_provenance, list_of(:ai_provenance_item) do
      resolve(&AIProvenance.target_item_provenance/3)
    end
  end

  object :ai_activity_event do
    field(:id, non_null(:id))
    field(:activity_target_id, non_null(:id))
    field(:event_type, non_null(:string))
    field(:actor, :string)
    field(:occurred_at, non_null(:datetime))
    field(:value_before, :json)
    field(:value_after, :json)
    field(:notes, :string)
    field(:premis_event_type, :string)
    field(:outcome, :string)
    field(:outcome_detail, :string)
    field(:c2pa_action, :string)
    field(:c2pa_assertion_label, :string)
    field(:agent_links, list_of(:ai_activity_event_agent))
  end

  object :ai_agent do
    field(:id, non_null(:id))
    field(:agent_type, non_null(:string))
    field(:name, non_null(:string))
    field(:identifier_type, :string)
    field(:identifier_value, :string)
    field(:version, :string)
    field(:metadata, :json)
  end

  object :ai_activity_event_agent do
    field(:id, non_null(:id))
    field(:activity_event_id, non_null(:id))
    field(:agent_id, non_null(:id))
    field(:role, non_null(:string))
    field(:agent, :ai_agent)
  end

  object :ai_provenance_summary_entry do
    field(:field_path, non_null(:string))
    field(:target_type, non_null(:string))
    field(:target_id, non_null(:string))
    field(:operation, :string)
    field(:origin, non_null(:string))
    field(:proposed_value, :json)
    field(:current_value, :json)
    field(:item_provenance, list_of(:ai_provenance_item))
    field(:human_oversight_level, :string)
    field(:status, :string)
    field(:activity_id, non_null(:id))
    field(:activity_type, :string)
    field(:ai_use_type, :string)
    field(:access_mode, :string)
    field(:reversibility, :string)
    field(:model, :string)
    field(:model_provider, :string)
    field(:model_version, :string)
    field(:model_type, :string)
    field(:generated_at, :datetime)
    field(:reviewer, :string)
    field(:reviewed_at, :datetime)
    field(:applied_at, :datetime)
    field(:latest_event_type, :string)
    field(:source_count, :integer)
    field(:citation_completeness, :string)
    field(:premis, :json)
    field(:c2pa, :json)
  end

  @desc "Per-item AI attribution for a multivalued field (e.g. one subject term)."
  object :ai_provenance_item do
    field(:id, :string)
    field(:origin, :string)
  end
end
