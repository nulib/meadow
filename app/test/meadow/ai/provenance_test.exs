defmodule Meadow.AI.ProvenanceTest do
  use Meadow.DataCase

  alias Meadow.AI.Provenance
  alias Meadow.AI.Provenance.Export.{C2PAReadiness, PREMIS, UVA}

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

      # Non-Work targets are keyed by field_path plus target_id so distinct
      # annotations sharing a field_path never collapse into one entry.
      summary_key = "file_set_annotations.content:#{annotation_id}"

      assert %{
               ^summary_key => %{
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

      # Description: the AI's paragraph was edited in place, so its per-item
      # entry is keyed by the *current* value and carries the human-edit origin
      # rather than disappearing once it no longer matches the AI's wording.
      description_summary =
        Provenance.work_summary(work.id)
        |> Enum.find(&(&1.field_path == "descriptive_metadata.description"))

      assert description_summary.item_provenance == [
               %{id: "Reviewer description", origin: "ai_assisted_human_modified"}
             ]
    end
  end

  describe "plan-change row rejection" do
    test "records a rejection when a proposed row is removed, keeping origin" do
      work = work_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          ai_use_type: "metadata_generation",
          work_id: work.id,
          status: "completed"
        })

      proposed_location = [%{term: %{id: "loc1", label: "Illinois--Evanston"}}]

      Provenance.record_targets_for_operations(
        activity,
        "Work",
        work.id,
        %{
          add: %{
            descriptive_metadata: %{
              location: proposed_location,
              subject: ["AI subject"]
            }
          }
        },
        origin: "ai_generated",
        status: "proposed",
        event_type: "proposed"
      )

      location_before =
        Provenance.get_activity!(activity.id).targets
        |> Enum.find(&(&1.field_path == "descriptive_metadata.location"))

      change_before = %{
        ai_activity_id: activity.id,
        work_id: work.id,
        add: %{
          descriptive_metadata: %{
            location: proposed_location,
            subject: ["AI subject"]
          }
        },
        delete: %{},
        replace: %{}
      }

      # Reviewer deletes the location row and edits the subject.
      Provenance.record_plan_manual_edit(
        change_before,
        %{add: %{descriptive_metadata: %{subject: ["Reviewer subject"]}}},
        "bmq449"
      )

      targets = Provenance.get_activity!(activity.id).targets
      location = Enum.find(targets, &(&1.field_path == "descriptive_metadata.location"))
      subject = Enum.find(targets, &(&1.field_path == "descriptive_metadata.subject"))

      # Removing a never-applied proposal is a rejection of the AI suggestion,
      # not a replacement: origin (authorship) stays intact.
      assert location.origin == "ai_generated"
      assert location.status == "rejected"
      assert location.human_oversight_level == location_before.human_oversight_level

      rejected = Enum.find(location.events, &(&1.event_type == "rejected"))
      assert rejected.actor == "bmq449"
      assert rejected.value_before == location_before.proposed_value
      assert is_nil(rejected.value_after)
      assert rejected.premis_event_type == "validation"
      assert rejected.outcome == "failure"
      assert is_nil(rejected.c2pa_action)

      # Editing a surviving row still records an AI-assisted human edit.
      assert subject.origin == "ai_assisted_human_modified"
      assert subject.status == "reviewed"

      human_edited = Enum.find(subject.events, &(&1.event_type == "human_edited"))
      assert human_edited.actor == "bmq449"
      assert human_edited.value_after == %{"value" => ["Reviewer subject"]}
    end
  end

  describe "rejected plan over existing human content" do
    test "keeps human content attributed to humans" do
      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Test title",
            description: ["Human description"]
          }
        })

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          ai_use_type: "metadata_generation",
          work_id: work.id,
          status: "completed"
        })

      # The AI proposes swapping the human value for its own: delete + add on
      # the same field, as the planner agent records via update_plan_change.
      operations = %{
        delete: %{descriptive_metadata: %{description: ["Human description"]}},
        add: %{descriptive_metadata: %{description: ["AI description"]}}
      }

      Provenance.record_targets_for_operations(
        activity,
        "Work",
        work.id,
        operations,
        origin: "ai_generated",
        status: "proposed",
        event_type: "proposed",
        prior_values: Provenance.prior_values_for_operations(work, operations)
      )

      targets = Provenance.get_activity!(activity.id).targets
      delete_target = Enum.find(targets, &(&1.operation == "delete"))
      add_target = Enum.find(targets, &(&1.operation == "add"))

      # A delete over existing content modifies human content; the AI did not
      # author the value it proposes to remove.
      assert delete_target.origin == "ai_modified_human_content"
      assert delete_target.source_value_snapshot == %{"value" => ["Human description"]}
      assert delete_target.digital_source_type_uri == Provenance.enhanced_source_type()
      assert add_target.origin == "ai_generated"

      # The delete target's items are content being removed, never AI items.
      assert Provenance.item_provenance(delete_target) == []

      change = %{ai_activity_id: activity.id, work_id: work.id}
      Provenance.record_review_for_plan_change(change, "rejected", "bmq449", "Not needed")

      summary =
        work.id
        |> Provenance.work_summary()
        |> Enum.find(&(&1.field_path == "descriptive_metadata.description"))

      assert summary.status == "rejected"

      # Never-applied targets contribute no per-item attribution, so the
      # human-entered value keeps no AI badge on the About tab.
      assert summary.item_provenance == []
    end
  end

  describe "item_provenance reconciliation" do
    alias Meadow.AI.Provenance.Schemas.{Event, Target}

    defp target_with_events(origin, proposed, current) do
      %Target{
        target_type: "Work",
        target_id: "w1",
        field_path: "descriptive_metadata.description",
        origin: origin,
        proposed_value: %{"value" => proposed},
        events: [
          %Event{
            event_type: "proposed",
            value_after: %{"value" => proposed},
            occurred_at: ~U[2026-01-01 00:00:00.000000Z]
          },
          %Event{
            event_type: "applied",
            value_after: %{"value" => current},
            occurred_at: ~U[2026-01-01 00:01:00.000000Z]
          }
        ]
      }
    end

    test "keeps unchanged AI items as ai_generated" do
      target = target_with_events("ai_generated", ["A", "B"], ["A", "B"])

      assert Provenance.item_provenance(target) == [
               %{id: "A", origin: "ai_generated"},
               %{id: "B", origin: "ai_generated"}
             ]
    end

    test "attributes an in-place edit of one item to the human, keyed by its new value" do
      target = target_with_events("ai_assisted_human_modified", ["A", "B"], ["A", "B edited"])

      assert Provenance.item_provenance(target) == [
               %{id: "A", origin: "ai_generated"},
               %{id: "B edited", origin: "ai_assisted_human_modified"}
             ]
    end

    test "omits a human-added item that carries no AI lineage" do
      target = target_with_events("ai_assisted_human_modified", ["A"], ["A", "Human added"])

      assert Provenance.item_provenance(target) == [%{id: "A", origin: "ai_generated"}]
    end

    test "drops an AI item a human removed" do
      target = target_with_events("ai_assisted_human_modified", ["A", "B"], ["A"])

      assert Provenance.item_provenance(target) == [%{id: "A", origin: "ai_generated"}]
    end

    test "carries the ai_modified_human_content origin onto an edited item" do
      target = target_with_events("ai_modified_human_content", ["A"], ["A edited"])

      assert Provenance.item_provenance(target) == [
               %{id: "A edited", origin: "ai_modified_human_content"}
             ]
    end

    test "identifies note items by their text so each note is attributed" do
      notes = [
        %{"note" => "First note", "type" => %{"id" => "GENERAL_NOTE"}},
        %{"note" => "Second note", "type" => %{"id" => "LOCAL_NOTE"}}
      ]

      target = target_with_events("ai_generated", notes, notes)

      assert Provenance.item_provenance(target) == [
               %{id: "First note", origin: "ai_generated"},
               %{id: "Second note", origin: "ai_generated"}
             ]
    end

    test "identifies related_url items by their url" do
      urls = [
        %{"url" => "https://example.com/a", "label" => %{"id" => "RELATED_INFO"}},
        %{"url" => "https://example.com/b", "label" => %{"id" => "RELATED_INFO"}}
      ]

      target = target_with_events("ai_generated", urls, urls)

      assert Provenance.item_provenance(target) == [
               %{id: "https://example.com/a", origin: "ai_generated"},
               %{id: "https://example.com/b", origin: "ai_generated"}
             ]
    end

    test "ignores a valueless review event when determining the current value" do
      # The applied event is the chronologically latest value, but the earlier
      # `approved` event has a larger microsecond component. Comparing
      # `occurred_at` by raw term order (microsecond before second) would wrongly
      # pick the valueless review event and drop all per-item attribution.
      target = %Target{
        target_type: "Work",
        target_id: "w1",
        field_path: "descriptive_metadata.description",
        origin: "ai_generated",
        proposed_value: %{"value" => ["A", "B"]},
        events: [
          %Event{
            event_type: "proposed",
            value_after: %{"value" => ["A", "B"]},
            occurred_at: ~U[2026-01-01 00:00:00.100000Z]
          },
          %Event{
            event_type: "approved",
            value_after: nil,
            occurred_at: ~U[2026-01-01 00:00:05.465193Z]
          },
          %Event{
            event_type: "applied",
            value_after: %{"value" => ["A", "B"]},
            occurred_at: ~U[2026-01-01 00:00:07.207908Z]
          }
        ]
      }

      assert Provenance.item_provenance(target) == [
               %{id: "A", origin: "ai_generated"},
               %{id: "B", origin: "ai_generated"}
             ]
    end

    test "unions per-item provenance across multiple targets for the same field" do
      work = work_fixture(%{descriptive_metadata: %{keywords: []}})

      # Two separate activities each contribute one keyword to the same field.
      for kw <- ["First keyword", "Second keyword"] do
        {:ok, activity} =
          Provenance.create_activity(%{
            activity_type: "metadata_generation",
            ai_use_type: "metadata_generation",
            work_id: work.id,
            status: "completed"
          })

        Provenance.record_targets_for_operations(
          activity,
          "Work",
          work.id,
          %{add: %{descriptive_metadata: %{keywords: [kw]}}},
          origin: "ai_generated",
          status: "applied",
          event_type: "applied"
        )
      end

      summary =
        Provenance.work_summary(work.id)
        |> Enum.find(&(&1.field_path == "descriptive_metadata.keywords"))

      # Both keywords are surfaced even though they come from different targets;
      # collapsing to a single representative target would drop one.
      assert Enum.sort(Enum.map(summary.item_provenance, & &1.id)) == [
               "First keyword",
               "Second keyword"
             ]

      assert Enum.all?(summary.item_provenance, &(&1.origin == "ai_generated"))
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

    test "except: skips fields recorded through the attestation path", %{work: work} do
      edited = put_in(work.descriptive_metadata.description, ["Human-edited description"])

      Provenance.record_work_manual_edit(work, edited, "bmq449",
        except: ["descriptive_metadata.description"]
      )

      # Untouched by the manual-edit path: still the original AI applied state.
      assert %{"descriptive_metadata.description" => %{origin: "ai_generated"}} =
               Provenance.target_summary_map("Work", work.id)
    end

    test "record_work_manual_edit!/4 records the same transitions as the lax variant",
         %{work: work} do
      edited = put_in(work.descriptive_metadata.description, ["Human-edited description"])

      assert :ok = Provenance.record_work_manual_edit!(work, edited, "bmq449")

      entry =
        Provenance.work_summary(work.id)
        |> Enum.find(&(&1.field_path == "descriptive_metadata.description"))

      assert entry.origin == "ai_assisted_human_modified"
      assert entry.latest_event_type == "human_edited"
      assert entry.human_oversight_level == "human_modified"
    end

    test "record_work_manual_edit!/4 raises where the lax variant rescues and logs",
         %{work: work} do
      # A tuple can't be JSON-encoded, so recording the event's value_after
      # fails. The lax variant swallows the failure; the strict variant raises
      # so a caller's enclosing transaction rolls back.
      edited = put_in(work.descriptive_metadata.description, {:not, :encodable})

      assert :ok = Provenance.record_work_manual_edit(work, edited, "bmq449")

      assert_raise Protocol.UndefinedError, fn ->
        Provenance.record_work_manual_edit!(work, edited, "bmq449")
      end
    end
  end

  describe "explicit human attestation" do
    setup do
      work =
        work_fixture(%{
          descriptive_metadata: %{title: "AI title", description: ["AI description"]}
        })

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_direct_apply",
          model: "test-model",
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

      %{work: work}
    end

    defp title_entry(work_id) do
      Provenance.work_summary(work_id)
      |> Enum.find(&(&1.field_path == "descriptive_metadata.title"))
    end

    defp title_events(work_id) do
      [target] = Provenance.list_activities(work_id: work_id) |> hd() |> Map.fetch!(:targets)
      target.events
    end

    test "different value records human_attested_after_ai and preserves AI history", %{work: work} do
      after_work = put_in(work.descriptive_metadata.title, "Cataloger title")

      assert {:ok, ["descriptive_metadata.title"]} =
               Provenance.record_work_human_attestation(
                 work,
                 after_work,
                 ["descriptive_metadata.title"],
                 "bmq449",
                 reason: "Re-entered from catalog record"
               )

      entry = title_entry(work.id)
      assert entry.origin == "human_attested_after_ai"
      assert entry.status == "applied"
      assert entry.latest_event_type == "human_attested"
      assert entry.human_oversight_level == "human_attested"
      refute entry.origin == "ai_assisted_human_modified"

      # The summary's value reflects the live (attested) value, not the stale AI
      # proposal, so the Provenance tab agrees with the work's About tab.
      assert entry.proposed_value == %{"value" => "AI title"}
      assert entry.current_value == %{"value" => "Cataloger title"}

      event_types = title_events(work.id) |> Enum.map(& &1.event_type)
      assert "applied" in event_types
      assert "human_attested" in event_types

      attested = title_events(work.id) |> Enum.find(&(&1.event_type == "human_attested"))
      assert attested.actor == "bmq449"
      assert attested.notes == "Re-entered from catalog record"
      assert attested.value_before == %{"value" => "AI title"}
      assert attested.value_after == %{"value" => "Cataloger title"}
      assert attested.premis_event_type == "metadata modification"
      assert attested.c2pa_action == "c2pa.edited"
    end

    test "identical value is allowed and records equal before/after", %{work: work} do
      assert {:ok, ["descriptive_metadata.title"]} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.title"],
                 "bmq449"
               )

      entry = title_entry(work.id)
      assert entry.origin == "human_attested_after_ai"
      assert entry.latest_event_type == "human_attested"

      attested = title_events(work.id) |> Enum.find(&(&1.event_type == "human_attested"))
      assert attested.value_before == %{"value" => "AI title"}
      assert attested.value_after == %{"value" => "AI title"}
    end

    test "field with no AI provenance returns a validation error and fabricates nothing", %{
      work: work
    } do
      assert {:error, [{"descriptive_metadata.description", :no_ai_provenance}]} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.description"],
                 "bmq449"
               )

      # The title (the only AI field) is untouched.
      assert title_entry(work.id).origin == "ai_generated"
    end

    test "requires an actor", %{work: work} do
      assert {:error, [actor: :missing_actor]} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.title"],
                 nil
               )

      assert title_entry(work.id).origin == "ai_generated"
    end
  end

  describe "per-item human attestation" do
    setup do
      work =
        work_fixture(%{descriptive_metadata: %{description: ["Desc A", "Desc B"]}})

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_direct_apply",
          model: "test-model",
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

      %{work: work}
    end

    defp description_summary(work_id) do
      Provenance.work_summary(work_id)
      |> Enum.find(&(&1.field_path == "descriptive_metadata.description"))
    end

    test "attests one item and leaves siblings as AI generated", %{work: work} do
      assert {:ok, ["descriptive_metadata.description"]} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.description"],
                 "bmq449",
                 item_ids: ["Desc A"],
                 reason: "Verified against finding aid"
               )

      summary = description_summary(work.id)

      # The field as a whole is NOT reclassified — only the named item is.
      assert summary.origin == "ai_generated"

      assert summary.item_provenance == [
               %{id: "Desc A", origin: "human_attested_after_ai"},
               %{id: "Desc B", origin: "ai_generated"}
             ]

      # The field's live value is unchanged by a per-item attestation.
      assert summary.current_value == %{"value" => ["Desc A", "Desc B"]}
    end

    test "records a human_attested event scoped to the item", %{work: work} do
      assert {:ok, _} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.description"],
                 "bmq449",
                 item_ids: ["Desc A"],
                 reason: "Verified"
               )

      [target] = Provenance.list_activities(work_id: work.id) |> hd() |> Map.fetch!(:targets)
      attested = Enum.find(target.events, &(&1.event_type == "human_attested"))

      assert attested.item_identifier == "Desc A"
      assert attested.actor == "bmq449"
      assert attested.notes == "Verified"
      assert attested.value_before == %{"value" => "Desc A"}
      assert attested.value_after == %{"value" => "Desc A"}
    end

    test "attesting multiple items records one event each", %{work: work} do
      assert {:ok, _} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.description"],
                 "bmq449",
                 item_ids: ["Desc A", "Desc B"]
               )

      assert description_summary(work.id).item_provenance == [
               %{id: "Desc A", origin: "human_attested_after_ai"},
               %{id: "Desc B", origin: "human_attested_after_ai"}
             ]
    end

    test "an item id with no AI lineage is an error and fabricates nothing", %{work: work} do
      assert {:error, [{"descriptive_metadata.description", :no_ai_provenance}]} =
               Provenance.record_work_human_attestation(
                 work,
                 work,
                 ["descriptive_metadata.description"],
                 "bmq449",
                 item_ids: ["Not an AI item"]
               )

      # No attestation recorded: both items keep their AI origin.
      assert Enum.all?(
               description_summary(work.id).item_provenance,
               &(&1.origin == "ai_generated")
             )
    end
  end

  describe "field provenance lifecycle (integration)" do
    @lifecycle_path "descriptive_metadata.description"

    # Drive one AI generation/edit of the description through the real plan
    # pipeline: a fresh activity proposes a `replace`, then applies it. The
    # applied origin is decided by `finalize_apply_target!` — an apply over a
    # non-empty `prior_value` is recorded as `ai_modified_human_content` ("AI
    # edited"); over an empty one it stays `ai_generated`. Each call creates a new
    # target that supersedes the field's previous one.
    defp apply_ai_edit(work, value, prior_value) do
      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          ai_use_type: "metadata_generation",
          work_id: work.id,
          status: "completed"
        })

      operations = %{replace: %{descriptive_metadata: %{description: value}}}

      Provenance.record_targets_for_operations(activity, "Work", work.id, operations,
        origin: "ai_generated",
        status: "proposed",
        event_type: "proposed"
      )

      plan_change = %{
        ai_activity_id: activity.id,
        work_id: work.id,
        add: %{},
        delete: %{},
        replace: operations.replace
      }

      Provenance.record_apply_for_plan_change(plan_change, "system", %{
        @lifecycle_path => prior_value
      })

      activity
    end

    # The work_summary entry for the description field — the source of the
    # About-tab badge (its `origin`) and the field's live provenance state.
    defp lifecycle_entry(work_id) do
      Provenance.work_summary(work_id)
      |> Enum.find(&(&1.field_path == @lifecycle_path))
    end

    # A work struct carrying a given description value, for the functions that
    # read the live field value (manual edit, attestation) rather than a plan.
    defp work_with_description(work, value),
      do: put_in(work.descriptive_metadata.description, value)

    test "walks a field from AI generated through attestation and AI/human edits" do
      v1 = ["AI description v1"]
      v3 = ["AI description v3"]
      v4 = ["Human edited v4"]
      v5 = ["AI description v5"]

      work = work_fixture(%{descriptive_metadata: %{description: v1}})

      # 1. AI generates the description (applied over an empty prior value).
      apply_ai_edit(work, v1, [])
      entry = lifecycle_entry(work.id)
      assert entry.origin == "ai_generated"
      assert entry.latest_event_type == "applied"

      # 2. A cataloger attests the AI value as human-authored (no content change).
      at_v1 = work_with_description(work, v1)

      assert {:ok, [@lifecycle_path]} =
               Provenance.record_work_human_attestation(at_v1, at_v1, [@lifecycle_path], "bmq449",
                 reason: "Verified against the source"
               )

      entry = lifecycle_entry(work.id)
      assert entry.origin == "human_attested_after_ai"
      assert entry.latest_event_type == "human_attested"

      # 3. AI re-edits the field, overwriting the human-attested value ("AI edited").
      apply_ai_edit(work, v3, v1)
      entry = lifecycle_entry(work.id)
      assert entry.origin == "ai_modified_human_content"
      assert entry.latest_event_type == "applied"

      # 4. A human edits the AI value in place ("AI + human edited").
      assert :ok =
               Provenance.record_work_manual_edit(
                 work_with_description(work, v3),
                 work_with_description(work, v4),
                 "bmq449"
               )

      entry = lifecycle_entry(work.id)
      assert entry.origin == "ai_assisted_human_modified"
      assert entry.latest_event_type == "human_edited"

      # 5. AI re-edits again, overwriting the human-edited value ("AI edited").
      apply_ai_edit(work, v5, v4)
      entry = lifecycle_entry(work.id)
      assert entry.origin == "ai_modified_human_content"
      assert entry.latest_event_type == "applied"

      # 6. The cataloger attests the latest AI value again ("Human attested").
      at_v5 = work_with_description(work, v5)

      assert {:ok, [@lifecycle_path]} =
               Provenance.record_work_human_attestation(at_v5, at_v5, [@lifecycle_path], "bmq449")

      entry = lifecycle_entry(work.id)
      assert entry.origin == "human_attested_after_ai"
      assert entry.latest_event_type == "human_attested"

      # Activity log: each AI edit is its own activity/target; human attest/edit
      # append to the current target. Three activities, oldest first.
      activities =
        Provenance.list_activities(work_id: work.id)
        |> Enum.sort_by(& &1.inserted_at, DateTime)

      assert length(activities) == 3

      # Each activity owns one description target; its event timeline tells the
      # per-stage story.
      event_types =
        Enum.map(activities, fn activity ->
          [target] = activity.targets

          target.events
          |> Enum.sort_by(& &1.occurred_at, DateTime)
          |> Enum.map(& &1.event_type)
        end)

      assert event_types == [
               ["proposed", "applied", "human_attested"],
               ["proposed", "applied", "human_edited"],
               ["proposed", "applied", "human_attested"]
             ]

      # The disposition of each target matches the lifecycle's resting origins.
      assert Enum.map(activities, fn activity -> hd(activity.targets).origin end) == [
               "human_attested_after_ai",
               "ai_assisted_human_modified",
               "human_attested_after_ai"
             ]

      # Spot-check the log's content, not just its shape: the step-4 edit captured
      # the AI -> human value transition...
      [_a1, a2, _a3] = activities
      [t2] = a2.targets
      human_edited = Enum.find(t2.events, &(&1.event_type == "human_edited"))
      assert human_edited.actor == "bmq449"
      assert human_edited.value_before == %{"value" => v3}
      assert human_edited.value_after == %{"value" => v4}

      # ...and the first attestation recorded an unchanged before/after value.
      [a1 | _] = activities
      [t1] = a1.targets
      attested = Enum.find(t1.events, &(&1.event_type == "human_attested"))
      assert attested.actor == "bmq449"
      assert attested.value_before == %{"value" => v1}
      assert attested.value_after == %{"value" => v1}
      assert attested.notes == "Verified against the source"
    end
  end

  describe "field summary supersession" do
    alias Meadow.AI.Provenance.Schemas.Event
    alias Meadow.Repo

    defp record_field_target(work, attrs, event_type) do
      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          model: "test-model",
          work_id: work.id,
          status: "completed"
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          Map.merge(
            %{
              target_type: "Work",
              target_id: work.id,
              field_path: "descriptive_metadata.description",
              operation: "replace"
            },
            attrs
          ),
          event_type
        )

      activity
    end

    # A human removes an AI value (recorded "Human replaced AI" / deleted), then
    # a later AI activity regenerates the same field. The field's current
    # provenance is the new AI value — the "Human replaced AI" entry must not
    # stick around. The tie-break must be deterministic even when the two
    # targets' events share an identical timestamp, so we force that here.
    test "a later AI target supersedes an earlier human replacement on a tied timestamp" do
      work = work_fixture(%{descriptive_metadata: %{description: ["AI desc"]}})

      record_field_target(
        work,
        %{
          proposed_value: ["AI desc"],
          origin: "human_replacement_after_ai_suggestion",
          status: "deleted"
        },
        "human_replaced"
      )

      record_field_target(
        work,
        %{proposed_value: ["New AI desc"], origin: "ai_generated", status: "applied"},
        "applied"
      )

      # Collapse both events onto the same instant so the result is decided by
      # the deterministic tie-break (newest target wins), not arbitrary row order.
      {2, _} = Repo.update_all(Event, set: [occurred_at: ~U[2026-06-25 00:00:00.000000Z]])

      assert [
               %{
                 field_path: "descriptive_metadata.description",
                 origin: "ai_generated",
                 status: "applied"
               }
             ] = Provenance.work_summary(work.id)
    end
  end

  describe "transfer_file_set_provenance/3" do
    alias Meadow.AI.Provenance.Schemas.{Activity, Source}
    alias Meadow.Repo

    setup do
      source_collection = collection_fixture(%{title: "Source Collection"})
      destination_collection = collection_fixture(%{title: "Destination Collection"})

      source_work = work_with_file_sets_fixture(2, %{collection_id: source_collection.id})
      destination_work = work_fixture(%{collection_id: destination_collection.id})

      [file_set, other_file_set] = source_work.file_sets

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "transcription",
          ai_use_type: "transcription",
          model: "test-model",
          work_id: source_work.id,
          file_set_id: file_set.id,
          status: "completed"
        })

      {:ok, _source} = Provenance.add_source(activity, Provenance.file_set_source_attrs(file_set))

      annotation_id = Ecto.UUID.generate()

      {:ok, target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "FileSetAnnotation",
            target_id: annotation_id,
            field_path: "file_set_annotations.content",
            operation: "add",
            proposed_value: "Generated transcript",
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      {:ok,
       source_work: source_work,
       destination_work: destination_work,
       destination_collection: destination_collection,
       file_set: file_set,
       other_file_set: other_file_set,
       activity: activity,
       target: target,
       annotation_id: annotation_id}
    end

    test "re-points activity and refreshes source citation fields", %{
      source_work: source_work,
      destination_work: destination_work,
      destination_collection: destination_collection,
      file_set: file_set,
      activity: activity
    } do
      assert {:ok, %{activities: 1, sources: 1, events: 1}} =
               Provenance.transfer_file_set_provenance([file_set.id], destination_work.id)

      activity = Repo.get!(Activity, activity.id)
      assert activity.work_id == destination_work.id

      assert [source] = Repo.all(from(s in Source, where: s.file_set_id == ^file_set.id))
      assert source.work_id == destination_work.id
      assert source.collection_id == destination_collection.id
      assert source.collection_title == "Destination Collection"
      assert source.access_link =~ destination_work.id
      refute source.access_link =~ source_work.id

      # File set identity fields are snapshots of the file set itself, untouched
      assert source.item_id == file_set.id
      assert source.source_snapshot == %{"accession_number" => file_set.accession_number}
    end

    test "appends a transferred audit event with old and new work ids", %{
      source_work: source_work,
      destination_work: destination_work,
      file_set: file_set,
      target: target
    } do
      {:ok, _} = Provenance.transfer_file_set_provenance([file_set.id], destination_work.id)

      target = Repo.preload(target, :events, force: true)
      assert transfer_event = Enum.find(target.events, &(&1.event_type == "transferred"))

      assert transfer_event.premis_event_type == "transfer"
      assert transfer_event.outcome == "success"
      assert transfer_event.notes =~ source_work.id
      assert transfer_event.notes =~ destination_work.id
      assert transfer_event.outcome_detail ==
               "from_work_id=#{source_work.id} to_work_id=#{destination_work.id}"

      assert is_nil(transfer_event.value_before)
      assert is_nil(transfer_event.value_after)
    end

    test "work summaries follow the file set without losing the current value", %{
      source_work: source_work,
      destination_work: destination_work,
      file_set: file_set,
      annotation_id: annotation_id
    } do
      {:ok, _} = Provenance.transfer_file_set_provenance([file_set.id], destination_work.id)

      assert Provenance.work_summary(source_work.id) == []

      assert [
               %{
                 target_type: "FileSetAnnotation",
                 target_id: ^annotation_id,
                 current_value: %{"value" => "Generated transcript"},
                 latest_event_type: "transferred"
               }
             ] = Provenance.work_summary(destination_work.id)

      assert [_] = Provenance.list_activities(work_id: destination_work.id)
      assert [] == Provenance.list_activities(work_id: source_work.id)
    end

    test "leaves work-level activities and other file sets' provenance untouched", %{
      source_work: source_work,
      destination_work: destination_work,
      file_set: file_set,
      other_file_set: other_file_set
    } do
      {:ok, work_level_activity} =
        Provenance.create_activity(%{
          activity_type: "metadata_plan",
          work_id: source_work.id
        })

      {:ok, other_activity} =
        Provenance.create_activity(%{
          activity_type: "transcription",
          work_id: source_work.id,
          file_set_id: other_file_set.id
        })

      {:ok, _} =
        Provenance.add_source(other_activity, Provenance.file_set_source_attrs(other_file_set))

      assert {:ok, %{activities: 1, sources: 1, events: 1}} =
               Provenance.transfer_file_set_provenance([file_set.id], destination_work.id)

      assert Repo.get!(Activity, work_level_activity.id).work_id == source_work.id
      assert Repo.get!(Activity, other_activity.id).work_id == source_work.id

      assert [other_source] =
               Repo.all(from(s in Source, where: s.file_set_id == ^other_file_set.id))

      assert other_source.work_id == source_work.id
    end

    test "is idempotent and a no-op for empty input", %{
      destination_work: destination_work,
      file_set: file_set,
      target: target
    } do
      assert {:ok, %{activities: 0, sources: 0, events: 0}} =
               Provenance.transfer_file_set_provenance([], destination_work.id)

      {:ok, %{activities: 1}} =
        Provenance.transfer_file_set_provenance([file_set.id], destination_work.id)

      assert {:ok, %{activities: 0, events: 0}} =
               Provenance.transfer_file_set_provenance([file_set.id], destination_work.id)

      target = Repo.preload(target, :events, force: true)
      assert Enum.count(target.events, &(&1.event_type == "transferred")) == 1
    end
  end

  describe "work_ids_with_applied_ai_targets/2" do
    defp seed_lookup_target(work, origin, status) do
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
            proposed_value: ["value"],
            origin: origin,
            status: status
          },
          "proposed"
        )

      :ok
    end

    test "returns only works with applied, AI-involved targets" do
      ai_work = work_fixture()
      proposed_work = work_fixture()
      rejected_work = work_fixture()
      human_work = work_fixture()
      untouched_work = work_fixture()

      seed_lookup_target(ai_work, "ai_generated", "applied")
      seed_lookup_target(proposed_work, "ai_generated", "proposed")
      seed_lookup_target(rejected_work, "ai_generated", "rejected")
      seed_lookup_target(human_work, "human_generated", "applied")

      ids = [ai_work.id, proposed_work.id, rejected_work.id, human_work.id, untouched_work.id]

      assert Provenance.work_ids_with_applied_ai_targets(ids) == [ai_work.id]
    end

    test "returns an empty list for empty input" do
      assert Provenance.work_ids_with_applied_ai_targets([]) == []
    end
  end

  describe "ai_involved?/2" do
    test "true for an applied Work-level AI target" do
      work = work_fixture()
      seed_lookup_target(work, "ai_generated", "applied")

      assert Provenance.ai_involved?(Provenance.work_summary(work.id), work.id)
    end

    test "false when the only target is a transcription (FileSetAnnotation)" do
      work = work_fixture()

      {:ok, activity} =
        Provenance.create_activity(%{
          activity_type: "transcription",
          work_id: work.id,
          status: "completed"
        })

      {:ok, _target} =
        Provenance.record_target(
          activity,
          %{
            target_type: "FileSetAnnotation",
            target_id: Ecto.UUID.generate(),
            field_path: "file_set_annotations.content",
            operation: "replace",
            proposed_value: ["transcribed text"],
            origin: "ai_generated",
            status: "applied"
          },
          "applied"
        )

      refute Provenance.ai_involved?(Provenance.work_summary(work.id), work.id)
    end

    test "false when the AI target has not yet been applied" do
      work = work_fixture()
      seed_lookup_target(work, "ai_generated", "proposed")

      refute Provenance.ai_involved?(Provenance.work_summary(work.id), work.id)
    end

    test "false for a work with no provenance targets at all" do
      work = work_fixture()

      refute Provenance.ai_involved?(Provenance.work_summary(work.id), work.id)
    end
  end
end
