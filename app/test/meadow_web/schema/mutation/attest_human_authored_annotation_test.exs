defmodule MeadowWeb.Schema.Mutation.AttestHumanAuthoredAnnotationTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.AI.Provenance
  alias Meadow.Data.FileSets

  load_gql(MeadowWeb.Schema, "test/gql/AttestHumanAuthoredAnnotation.gql")

  # Seed a file set with an applied AI-generated transcription annotation so
  # there is AI provenance to attest.
  defp annotation_with_ai_provenance do
    file_set = file_set_fixture()

    {:ok, activity} =
      Provenance.create_activity(%{
        activity_type: "transcription",
        ai_use_type: "transcription",
        work_id: file_set.work_id,
        file_set_id: file_set.id,
        status: "completed"
      })

    {:ok, annotation} =
      FileSets.create_annotation(file_set, %{
        type: "transcription",
        status: "completed",
        content: "AI transcription text",
        ai_activity_id: activity.id
      })

    {:ok, _target} =
      Provenance.record_target(
        activity,
        %{
          target_type: "FileSetAnnotation",
          target_id: annotation.id,
          field_path: "file_set_annotations.content",
          operation: "replace",
          proposed_value: "AI transcription text",
          origin: "ai_generated",
          status: "applied"
        },
        "applied"
      )

    annotation
  end

  test "marks an AI transcription human-attested and preserves AI history" do
    annotation = annotation_with_ai_provenance()

    {:ok, result} =
      query_gql(
        variables: %{
          "annotation_id" => annotation.id,
          "reason" => "Verified against the image"
        },
        context: gql_context(%{role: :editor})
      )

    provenance = get_in(result, [:data, "attestHumanAuthoredAnnotation", "aiProvenance"])

    assert provenance["origin"] == "human_attested_after_ai"
    assert provenance["status"] == "applied"
    assert provenance["latestEventType"] == "human_attested"
  end

  test "returns an error for an annotation with no AI provenance" do
    file_set = file_set_fixture()

    {:ok, annotation} =
      FileSets.create_annotation(file_set, %{
        type: "caption",
        status: "completed",
        content: "human caption"
      })

    {:ok, result} =
      query_gql(
        variables: %{"annotation_id" => annotation.id},
        context: gql_context(%{role: :editor})
      )

    assert [%{message: "Could not attest annotation"}] = result.errors
  end

  test "viewers are not authorized" do
    annotation = annotation_with_ai_provenance()

    {:ok, result} =
      query_gql(
        variables: %{"annotation_id" => annotation.id},
        context: gql_context(%{role: :user})
      )

    assert %{errors: [%{message: "Forbidden", status: 403}]} = result
  end
end
