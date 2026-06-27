defmodule MeadowWeb.Schema.Mutation.AttestHumanAuthoredMetadataTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.AI.Provenance

  load_gql(MeadowWeb.Schema, "test/gql/AttestHumanAuthoredMetadata.gql")

  # Seed a work with an applied AI-generated title so there is AI provenance to
  # attest.
  defp work_with_ai_title do
    work = work_fixture(%{descriptive_metadata: %{title: "AI title"}})

    {:ok, activity} =
      Provenance.create_activity(%{
        activity_type: "metadata_direct_apply",
        work_id: work.id,
        status: "completed"
      })

    {:ok, _target} =
      Provenance.record_target(
        activity,
        %{
          target_type: "Work",
          target_id: work.id,
          field_path: "descriptive_metadata.title",
          operation: "replace",
          proposed_value: "AI title",
          origin: "ai_generated",
          status: "applied"
        },
        "applied"
      )

    work
  end

  test "marks an AI field human-attested and preserves the live value" do
    work = work_with_ai_title()

    {:ok, result} =
      query_gql(
        variables: %{
          "work_id" => work.id,
          "field_paths" => ["descriptive_metadata.title"],
          "reason" => "Verified against folder title"
        },
        context: gql_context(%{role: :editor})
      )

    summary = get_in(result, [:data, "attestHumanAuthoredMetadata", "aiProvenanceSummary"])
    title = Enum.find(summary, &(&1["fieldPath"] == "descriptive_metadata.title"))

    assert title["origin"] == "human_attested_after_ai"
    assert title["status"] == "applied"
    assert title["latestEventType"] == "human_attested"
  end

  # Seed a work with an applied AI-generated multivalued field (description) so
  # individual items can be attested.
  defp work_with_ai_descriptions do
    work = work_fixture(%{descriptive_metadata: %{description: ["Desc A", "Desc B"]}})

    {:ok, activity} =
      Provenance.create_activity(%{
        activity_type: "metadata_direct_apply",
        work_id: work.id,
        status: "completed"
      })

    {:ok, _target} =
      Provenance.record_target(
        activity,
        %{
          target_type: "Work",
          target_id: work.id,
          field_path: "descriptive_metadata.description",
          operation: "replace",
          proposed_value: ["Desc A", "Desc B"],
          origin: "ai_generated",
          status: "applied"
        },
        "applied"
      )

    work
  end

  test "attests a single item of a multivalued field, leaving siblings AI" do
    work = work_with_ai_descriptions()

    {:ok, result} =
      query_gql(
        variables: %{
          "work_id" => work.id,
          "field_paths" => ["descriptive_metadata.description"],
          "item_ids" => ["Desc A"],
          "reason" => "Verified"
        },
        context: gql_context(%{role: :editor})
      )

    summary = get_in(result, [:data, "attestHumanAuthoredMetadata", "aiProvenanceSummary"])
    description = Enum.find(summary, &(&1["fieldPath"] == "descriptive_metadata.description"))

    # The field as a whole stays AI generated; only the named item flips.
    assert description["origin"] == "ai_generated"

    assert description["itemProvenance"] == [
             %{"id" => "Desc A", "origin" => "human_attested_after_ai"},
             %{"id" => "Desc B", "origin" => "ai_generated"}
           ]
  end

  test "returns an error for a field with no AI provenance" do
    work = work_with_ai_title()

    {:ok, result} =
      query_gql(
        variables: %{
          "work_id" => work.id,
          "field_paths" => ["descriptive_metadata.description"]
        },
        context: gql_context(%{role: :editor})
      )

    assert [%{message: "Could not attest human-authored metadata"}] = result.errors
  end

  test "viewers are not authorized" do
    work = work_with_ai_title()

    {:ok, result} =
      query_gql(
        variables: %{
          "work_id" => work.id,
          "field_paths" => ["descriptive_metadata.title"]
        },
        context: gql_context(%{role: :user})
      )

    assert %{errors: [%{message: "Forbidden", status: 403}]} = result
  end
end
