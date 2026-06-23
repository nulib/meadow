defmodule Meadow.AI.ProvenanceTest do
  use Meadow.DataCase

  alias Meadow.AI.Provenance
  alias Meadow.AI.Provenance.Export.{C2PAReadiness, PREMIS, UVA}
  alias Meadow.AI.Provenance.LegacyNotes

  describe "activities" do
    test "creates activities, sources, targets, and events" do
      work = work_fixture()

      assert {:ok, activity} =
               Provenance.create_activity(%{
                 activity_type: "metadata_direct_apply",
                 model: "test-model",
                 work_id: work.id,
                 status: "completed"
               })

      assert {:ok, _source} =
               Provenance.add_source(activity, %{
                 item_id: work.id,
                 item_type: "Work",
                 work_id: work.id
               })

      assert {:ok, target} =
               Provenance.record_target(
                 activity,
                 %{
                   target_type: "Work",
                   target_id: work.id,
                   field_path: "descriptive_metadata.description",
                   operation: "replace",
                   proposed_value: ["A generated description."],
                   origin: "ai_generated",
                   status: "applied"
                 },
                 "applied"
               )

      activity = Provenance.get_activity!(activity.id)

      assert activity.prompt_hash == nil
      assert [%{work_id: work_id}] = activity.sources
      assert work_id == work.id
      assert [%{field_path: "descriptive_metadata.description"}] = activity.targets

      assert [%{event_type: "applied", value_after: %{"value" => ["A generated description."]}}] =
               target.events
    end

    test "summarizes latest provenance by work field" do
      work = work_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{activity_type: "metadata_plan", work_id: work.id})

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "Work",
            target_id: work.id,
            field_path: "descriptive_metadata.subject",
            operation: "add",
            proposed_value: [%{term: %{id: "mock1:result1"}}],
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      assert [
               %{
                 field_path: "descriptive_metadata.subject",
                 origin: "ai_generated",
                 activity_id: activity_id
               }
             ] = Provenance.work_summary(work.id)

      assert activity_id == activity.id
    end

    test "preserves target identity for non-work targets" do
      work = work_fixture()
      annotation_id = Ecto.UUID.generate()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "transcription",
          ai_use_type: "transcription",
          work_id: work.id
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "FileSetAnnotation",
            target_id: annotation_id,
            field_path: "file_set_annotations.content",
            operation: "replace",
            proposed_value: "Generated transcript",
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      assert [
               %{
                 target_type: "FileSetAnnotation",
                 target_id: ^annotation_id,
                 field_path: "file_set_annotations.content"
               }
             ] = Provenance.work_summary(work.id)

      assert %{
               "file_set_annotations.content" => %{
                 target_type: "FileSetAnnotation",
                 target_id: ^annotation_id
               }
             } = Provenance.target_summary_map("FileSetAnnotation", annotation_id)
    end

    test "exports UVA, PREMIS, and C2PA readiness projections" do
      work = work_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_direct_apply",
          ai_use_type: "metadata_generation",
          model: "test-model",
          work_id: work.id,
          status: "completed"
        })

      {:ok, _source} =
        Provenance.add_source(activity, %{
          collection_id: work.collection_id,
          collection_title: "Test Collection",
          item_id: work.id,
          item_type: "Work",
          work_id: work.id,
          holding_organization: "Northwestern University Libraries",
          access_link: "https://dc.example/items/#{work.id}"
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "Work",
            target_id: work.id,
            field_path: "descriptive_metadata.description",
            operation: "replace",
            proposed_value: ["Description"],
            origin: "ai_generated",
            status: "applied",
            c2pa_action: "c2pa.edited",
            digital_source_type_uri:
              "https://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia",
            human_oversight_level: "human_review_required"
          },
          "applied"
        )

      assert %{citation_completeness: "complete"} = UVA.work(work.id)
      assert %{objects: [_ | _], events: [_ | _]} = PREMIS.work(work.id)
      assert %{ready: true, activities: [%{targets: [%{ready: true}]}]} = C2PAReadiness.work(work.id)
    end
  end

  describe "generation vs modification classification" do
    setup do
      work = work_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          ai_use_type: "metadata_generation",
          work_id: work.id,
          status: "completed"
        })

      operations = %{replace: %{descriptive_metadata: %{description: ["New AI description"]}}}

      Provenance.record_targets_for_operations(activity, "Work", work.id, operations,
        origin: "ai_generated",
        status: "proposed",
        event_type: "proposed",
        target_attrs: %{
          digital_source_type_uri: Provenance.trained_source_type()
        }
      )

      plan_change = %{
        ai_activity_id: activity.id,
        work_id: work.id,
        add: %{},
        delete: %{},
        replace: %{descriptive_metadata: %{description: ["New AI description"]}}
      }

      %{work: work, plan_change: plan_change}
    end

    test "overwriting a prior human value is recorded as ai_modified_human_content", %{
      work: work,
      plan_change: plan_change
    } do
      Provenance.record_apply_for_plan_change(plan_change, "bmq449", %{
        "descriptive_metadata.description" => ["A human-authored description"]
      })

      assert %{
               "descriptive_metadata.description" => %{
                 origin: "ai_modified_human_content",
                 status: "applied",
                 operation: "replace",
                 c2pa: %{digital_source_type_uri: source_type}
               }
             } = Provenance.target_summary_map("Work", work.id)

      assert source_type == Provenance.enhanced_source_type()
    end

    test "applying over an empty prior value stays ai_generated", %{
      work: work,
      plan_change: plan_change
    } do
      Provenance.record_apply_for_plan_change(plan_change, "bmq449", %{
        "descriptive_metadata.description" => []
      })

      assert %{
               "descriptive_metadata.description" => %{
                 origin: "ai_generated",
                 status: "applied"
               }
             } = Provenance.target_summary_map("Work", work.id)
    end
  end

  describe "plan-change deletions" do
    setup do
      work =
        work_fixture(%{
          descriptive_metadata: %{description: ["An AI-generated description."]}
        })

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          ai_use_type: "metadata_generation",
          work_id: work.id,
          status: "completed"
        })

      # AI proposes deleting the (AI-generated) description.
      operations = %{delete: %{descriptive_metadata: %{description: ["An AI-generated description."]}}}

      Provenance.record_targets_for_operations(activity, "Work", work.id, operations,
        origin: "ai_generated",
        status: "proposed",
        event_type: "proposed"
      )

      plan_change = %{
        ai_activity_id: activity.id,
        work_id: work.id,
        add: %{},
        delete: %{descriptive_metadata: %{description: ["An AI-generated description."]}},
        replace: %{}
      }

      %{work: work, plan_change: plan_change}
    end

    test "applying a delete records a 'deleted' event and marks the target deleted", %{
      work: work,
      plan_change: plan_change
    } do
      Provenance.record_apply_for_plan_change(plan_change, "bmq449", %{
        "descriptive_metadata.description" => ["An AI-generated description."]
      })

      assert %{
               "descriptive_metadata.description" => %{
                 operation: "delete",
                 status: "deleted",
                 human_oversight_level: "human_modified",
                 latest_event_type: "deleted",
                 c2pa: %{action: "c2pa.removed"}
               }
             } = Provenance.target_summary_map("Work", work.id)
    end

    test "the 'deleted' event captures the removed value and is mapped to PREMIS deletion", %{
      work: work,
      plan_change: plan_change
    } do
      Provenance.record_apply_for_plan_change(plan_change, "bmq449", %{
        "descriptive_metadata.description" => ["An AI-generated description."]
      })

      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)
      deleted = Enum.find(target.events, &(&1.event_type == "deleted"))

      assert deleted.actor == "bmq449"
      assert deleted.value_before == %{"value" => ["An AI-generated description."]}
      assert is_nil(deleted.value_after)
      assert deleted.premis_event_type == "deletion"
      assert deleted.outcome == "success"
    end
  end

  describe "multi-stage human-mediated plan" do
    test "captures existing, AI-suggested, and human-mediated stages per field" do
      # A record that starts with a human title and description, no subjects.
      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Original human title",
            description: ["Original human description"]
          }
        })

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          ai_use_type: "metadata_generation",
          work_id: work.id,
          status: "completed"
        })

      # AI proposes: replace title + description, add three subjects.
      ai_subjects = ["AI subject 1", "AI subject 2", "AI subject 3"]

      Provenance.record_targets_for_operations(
        activity,
        "Work",
        work.id,
        %{
          replace: %{descriptive_metadata: %{title: ["AI title"], description: ["AI description"]}},
          add: %{descriptive_metadata: %{subject: ai_subjects}}
        },
        origin: "ai_generated",
        status: "proposed",
        event_type: "proposed"
      )

      change_before = %{
        ai_activity_id: activity.id,
        work_id: work.id,
        add: %{descriptive_metadata: %{subject: ai_subjects}},
        delete: %{},
        replace: %{descriptive_metadata: %{title: ["AI title"], description: ["AI description"]}}
      }

      # Reviewer keeps the title, edits the description, adds a fourth subject.
      reviewed_subjects = ai_subjects ++ ["Reviewer subject 4"]

      Provenance.record_plan_manual_edit(
        change_before,
        %{
          add: %{descriptive_metadata: %{subject: reviewed_subjects}},
          replace: %{
            descriptive_metadata: %{title: ["AI title"], description: ["Reviewer description"]}
          }
        },
        "bmq449"
      )

      plan_change_after = %{
        ai_activity_id: activity.id,
        work_id: work.id,
        add: %{descriptive_metadata: %{subject: reviewed_subjects}},
        delete: %{},
        replace: %{
          descriptive_metadata: %{title: ["AI title"], description: ["Reviewer description"]}
        }
      }

      Provenance.record_apply_for_plan_change(plan_change_after, "bmq449", %{
        "descriptive_metadata.title" => "Original human title",
        "descriptive_metadata.description" => ["Original human description"],
        "descriptive_metadata.subject" => []
      })

      targets =
        activity.id
        |> Provenance.get_activity!()
        |> Map.fetch!(:targets)

      target = fn path -> Enum.find(targets, &(&1.field_path == path)) end
      event_types = fn t -> Enum.map(t.events, & &1.event_type) end
      event = fn t, type -> Enum.find(t.events, &(&1.event_type == type)) end

      # Title: AI replaced a human value, reviewer left it -> modification.
      title = target.("descriptive_metadata.title")
      assert title.origin == "ai_modified_human_content"
      assert title.source_value_snapshot == %{"value" => "Original human title"}
      assert "proposed" in event_types.(title)
      assert "applied" in event_types.(title)

      # Description: AI suggested, reviewer edited -> AI-assisted human edit,
      # with all three stages recoverable from the event log + snapshot.
      description = target.("descriptive_metadata.description")
      assert description.origin == "ai_assisted_human_modified"
      assert description.source_value_snapshot == %{"value" => ["Original human description"]}
      assert "human_edited" in event_types.(description)
      assert "applied" in event_types.(description)

      assert event.(description, "proposed").value_after == %{"value" => ["AI description"]}

      assert event.(description, "human_edited").value_before == %{"value" => ["AI description"]}
      assert event.(description, "human_edited").value_after == %{"value" => ["Reviewer description"]}

      applied = event.(description, "applied")
      assert applied.value_before == %{"value" => ["Original human description"]}
      assert applied.value_after == %{"value" => ["Reviewer description"]}

      # Subjects: AI proposed three, reviewer added a fourth (field-level).
      subject = target.("descriptive_metadata.subject")
      assert subject.origin == "ai_assisted_human_modified"
      assert event.(subject, "proposed").value_after == %{"value" => ai_subjects}
      assert event.(subject, "human_edited").value_after == %{"value" => reviewed_subjects}

      # Per-item provenance attributes only the AI-proposed subjects, so a
      # reviewer-added item is not mislabeled as AI.
      subject_summary =
        Provenance.work_summary(work.id)
        |> Enum.find(&(&1.field_path == "descriptive_metadata.subject"))

      assert Enum.map(subject_summary.item_provenance, & &1.id) == ai_subjects
      assert Enum.all?(subject_summary.item_provenance, &(&1.origin == "ai_generated"))
    end
  end

  describe "direct work manual edit" do
    setup do
      work =
        work_fixture(%{
          descriptive_metadata: %{title: "T", description: ["AI description"]}
        })

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
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
            proposed_value: ["AI description"],
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      %{work: work}
    end

    test "flips an edited AI field to ai_assisted_human_modified", %{work: work} do
      edited = put_in(work.descriptive_metadata.description, ["Human-edited description"])

      Provenance.record_work_manual_edit(work, edited, "bmq449")

      entry =
        Provenance.work_summary(work.id)
        |> Enum.find(&(&1.field_path == "descriptive_metadata.description"))

      assert entry.origin == "ai_assisted_human_modified"
      assert entry.latest_event_type == "human_edited"
      assert entry.human_oversight_level == "human_modified"
    end

    test "stamps c2pa.edited on an edited AI field and its event", %{work: work} do
      edited = put_in(work.descriptive_metadata.description, ["Human-edited description"])

      Provenance.record_work_manual_edit(work, edited, "bmq449")

      assert %{"descriptive_metadata.description" => %{c2pa: %{action: "c2pa.edited"}}} =
               Provenance.target_summary_map("Work", work.id)

      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)
      event = Enum.find(target.events, &(&1.event_type == "human_edited"))

      assert event.c2pa_action == "c2pa.edited"
      assert event.premis_event_type == "metadata modification"
    end

    test "records a deletion when a human clears an AI field", %{work: work} do
      cleared = put_in(work.descriptive_metadata.description, [])

      Provenance.record_work_manual_edit(work, cleared, "bmq449")

      assert %{
               "descriptive_metadata.description" => %{
                 origin: "human_replacement_after_ai_suggestion",
                 status: "deleted",
                 human_oversight_level: "human_modified",
                 latest_event_type: "deleted",
                 c2pa: %{action: "c2pa.removed"}
               }
             } = Provenance.target_summary_map("Work", work.id)

      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)
      deleted = Enum.find(target.events, &(&1.event_type == "deleted"))

      assert deleted.actor == "bmq449"
      assert deleted.value_before == %{"value" => ["AI description"]}
      assert is_nil(deleted.value_after)
      assert deleted.premis_event_type == "deletion"
    end

    test "leaves the field untouched when nothing changed", %{work: work} do
      Provenance.record_work_manual_edit(work, work, "bmq449")

      assert %{"descriptive_metadata.description" => %{origin: "ai_generated"}} =
               Provenance.target_summary_map("Work", work.id)
    end

    test "returns :ok and records target reclassification and event atomically", %{work: work} do
      edited = put_in(work.descriptive_metadata.description, ["Human-edited description"])

      assert :ok = Provenance.record_work_manual_edit(work, edited, "bmq449")

      # The target was reclassified *and* an event was appended (not one without
      # the other), since both writes share a transaction.
      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)

      assert target.origin == "ai_assisted_human_modified"
      assert Enum.any?(target.events, &(&1.event_type == "human_edited"))
    end
  end

  describe "legacy notes" do
    test "dry-run detects recognized AI notes" do
      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Legacy",
            notes: [
              %{
                note:
                  "Some metadata created with the assistance of AI (claude-test) on 2026-02-09",
                type: %{id: "LOCAL_NOTE", scheme: "note_type", label: "Local Note"}
              }
            ]
          }
        })

      assert [
               %{
                 work_id: work_id,
                 parsed_model: "claude-test",
                 candidate_field_paths: ["descriptive_metadata"]
               }
             ] = LegacyNotes.dry_run()

      assert work_id == work.id
    end

    test "apply creates legacy provenance and removes only recognized AI notes" do
      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Legacy",
            notes: [
              %{
                note:
                  "Some metadata created with the assistance of AI (claude-test) on 2026-02-09",
                type: %{id: "LOCAL_NOTE", scheme: "note_type", label: "Local Note"}
              },
              %{
                note: "Keep this local note",
                type: %{id: "LOCAL_NOTE", scheme: "note_type", label: "Local Note"}
              }
            ]
          }
        })

      assert [%{work_id: work_id}] = LegacyNotes.apply()
      assert work_id == work.id

      fresh = Meadow.Data.Works.get_work!(work.id)
      assert Enum.map(fresh.descriptive_metadata.notes, & &1.note) == ["Keep this local note"]

      assert [
               %{
                 field_path: "descriptive_metadata",
                 origin: "legacy_ai_note_detected"
               }
             ] = Provenance.work_summary(work.id)
    end
  end
end
