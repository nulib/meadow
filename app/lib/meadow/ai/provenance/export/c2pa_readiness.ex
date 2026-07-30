defmodule Meadow.AI.Provenance.Export.C2PAReadiness do
  @moduledoc """
  Readiness projection for future C2PA manifests.

  This does not create a C2PA manifest. It reports whether Meadow has enough provenance
  metadata to map an activity/target to C2PA claims, assertions, ingredients, and AI
  disclosure assertions later.
  """

  alias Meadow.AI.Provenance

  @required_target_fields ~w(c2pa_action digital_source_type_uri human_oversight_level)a

  def work(work_id) do
    activities = Provenance.list_activities(work_id: work_id)

    %{
      standard: "C2PA",
      mode: "readiness",
      scope: %{work_id: work_id},
      ready: activities != [] and Enum.all?(activities, &activity_ready?/1),
      activities: Enum.map(activities, &activity_entry/1)
    }
  end

  defp activity_entry(activity) do
    targets = Enum.map(activity.targets || [], &target_entry/1)

    %{
      activity_id: activity.id,
      activity_type: activity.activity_type,
      model: activity.model,
      model_provider: activity.model_provider,
      model_version: activity.model_version,
      model_type: activity.model_type,
      manifest_id: activity.c2pa_manifest_id,
      claim_id: activity.c2pa_claim_id,
      validation_status: activity.c2pa_validation_status,
      signature_status: activity.c2pa_signature_status,
      ready: targets != [] and Enum.all?(targets, & &1.ready),
      targets: targets,
      ingredients: Enum.map(activity.sources || [], &ingredient/1)
    }
  end

  defp target_entry(target) do
    missing = missing_target_fields(target)

    %{
      target_type: target.target_type,
      target_id: target.target_id,
      field_path: target.field_path,
      action: target.c2pa_action,
      assertion_label: target.c2pa_assertion_label || "c2pa.ai-disclosure",
      digital_source_type_uri: target.digital_source_type_uri,
      ingredient_relationship: target.ingredient_relationship,
      human_oversight_level: target.human_oversight_level,
      manifest_id: target.c2pa_manifest_id,
      claim_id: target.c2pa_claim_id,
      validation_status: target.c2pa_validation_status,
      signature_status: target.c2pa_signature_status,
      ready: missing == [],
      missing: missing
    }
  end

  defp ingredient(source) do
    %{
      item_id: source.item_id,
      item_type: source.item_type,
      relationship: source.ingredient_relationship || source.relationship_role,
      access_link: source.access_link,
      content_hash: source.content_hash,
      content_hash_algorithm: source.content_hash_algorithm,
      manifest_id: source.c2pa_manifest_id,
      claim_id: source.c2pa_claim_id
    }
  end

  defp activity_ready?(activity) do
    targets = activity.targets || []
    targets != [] and Enum.all?(targets, &(missing_target_fields(&1) == []))
  end

  defp missing_target_fields(target) do
    Enum.reject(@required_target_fields, fn field ->
      target
      |> Map.get(field)
      |> present?()
    end)
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_), do: true
end
