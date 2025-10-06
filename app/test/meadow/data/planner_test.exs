defmodule Meadow.Data.PlannerTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Planner
  alias Meadow.Data.Schemas.{Plan, PlanChange}

  @valid_plan_attrs %{
    prompt: "Translate titles to Spanish in alternate_title field",
    query: "collection.id:abc-123"
  }

  @invalid_plan_attrs %{prompt: nil}

  setup do
    {:ok, plan} = Planner.create_plan(@valid_plan_attrs)
    work = work_fixture()
    {:ok, plan: plan, work: work}
  end

  describe "list_plans/0" do
    test "returns all plans" do
      assert length(Planner.list_plans()) >= 1
    end

    test "returns empty list when no plans exist" do
      Repo.delete_all(Plan)
      assert Planner.list_plans() == []
    end
  end

  describe "list_plans/1" do
    test "filters plans by status" do
      {:ok, pending_plan} = Planner.create_plan(@valid_plan_attrs)
      {:ok, approved_plan} = Planner.create_plan(@valid_plan_attrs)
      Planner.approve_plan(approved_plan)

      pending_plans = Planner.list_plans(status: :pending)
      pending_ids = Enum.map(pending_plans, & &1.id)
      assert pending_plan.id in pending_ids
      refute approved_plan.id in pending_ids
    end

    test "limits results" do
      Planner.create_plan(@valid_plan_attrs)
      Planner.create_plan(@valid_plan_attrs)
      Planner.create_plan(@valid_plan_attrs)

      plans = Planner.list_plans(limit: 2)
      assert length(plans) == 2
    end

    test "filters by user" do
      attrs_with_user = Map.put(@valid_plan_attrs, :user, "test_user@example.com")
      {:ok, user_plan} = Planner.create_plan(attrs_with_user)
      {:ok, _other_plan} = Planner.create_plan(@valid_plan_attrs)

      user_plans = Planner.list_plans(user: "test_user@example.com")
      assert length(user_plans) == 1
      assert hd(user_plans).id == user_plan.id
    end

    test "orders results" do
      # Clear existing plans to ensure clean test
      Repo.delete_all(Plan)

      {:ok, plan1} = Planner.create_plan(@valid_plan_attrs)
      {:ok, plan2} = Planner.create_plan(@valid_plan_attrs)

      plans_asc = Planner.list_plans(order: :asc)
      assert hd(plans_asc).id == plan1.id

      plans_desc = Planner.list_plans(order: :desc)
      assert hd(plans_desc).id == plan2.id
    end
  end

  describe "get_plan!/2" do
    test "returns the plan with given id", %{plan: plan} do
      assert %Plan{} = retrieved_plan = Planner.get_plan!(plan.id)
      assert retrieved_plan.id == plan.id
    end

    test "raises if plan doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Planner.get_plan!(Ecto.UUID.generate())
      end
    end

    test "preloads changes when requested", %{plan: plan, work: work} do
      Planner.create_plan_change(%{
        plan_id: plan.id,
        work_id: work.id,
        add: %{descriptive_metadata: %{title: "Updated"}}
      })

      retrieved_plan = Planner.get_plan!(plan.id, preload_changes: true)
      assert length(retrieved_plan.plan_changes) == 1
    end
  end

  describe "get_plan/2" do
    test "returns the plan with given id", %{plan: plan} do
      assert %Plan{} = retrieved_plan = Planner.get_plan(plan.id)
      assert retrieved_plan.id == plan.id
    end

    test "returns nil if plan doesn't exist" do
      assert Planner.get_plan(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_pending_plans/1" do
    test "returns only pending plans" do
      {:ok, pending1} = Planner.create_plan(@valid_plan_attrs)
      {:ok, pending2} = Planner.create_plan(@valid_plan_attrs)
      {:ok, approved} = Planner.create_plan(@valid_plan_attrs)
      Planner.approve_plan(approved)

      pending_plans = Planner.get_pending_plans()
      pending_ids = Enum.map(pending_plans, & &1.id)
      assert pending1.id in pending_ids
      assert pending2.id in pending_ids
      refute approved.id in pending_ids
    end

    test "returns empty list when no pending plans" do
      Repo.delete_all(Plan)
      {:ok, plan} = Planner.create_plan(@valid_plan_attrs)
      Planner.approve_plan(plan)

      assert Planner.get_pending_plans() == []
    end
  end

  describe "get_approved_plans/1" do
    test "returns only approved plans" do
      {:ok, pending} = Planner.create_plan(@valid_plan_attrs)
      {:ok, approved1} = Planner.create_plan(@valid_plan_attrs)
      {:ok, approved2} = Planner.create_plan(@valid_plan_attrs)
      Planner.approve_plan(approved1)
      Planner.approve_plan(approved2)

      approved_plans = Planner.get_approved_plans()
      approved_ids = Enum.map(approved_plans, & &1.id)
      assert approved1.id in approved_ids
      assert approved2.id in approved_ids
      refute pending.id in approved_ids
    end

    test "returns empty list when no approved plans" do
      Repo.delete_all(Plan)
      Planner.create_plan(@valid_plan_attrs)

      assert Planner.get_approved_plans() == []
    end
  end

  describe "create_plan/1" do
    test "with valid data creates a plan" do
      assert {:ok, %Plan{} = plan} = Planner.create_plan(@valid_plan_attrs)
      assert plan.prompt == @valid_plan_attrs.prompt
      assert plan.query == @valid_plan_attrs.query
      assert plan.status == :pending
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Planner.create_plan(@invalid_plan_attrs)
    end

    test "with user creates plan with user field" do
      attrs = Map.put(@valid_plan_attrs, :user, "test_user@example.com")
      assert {:ok, %Plan{} = plan} = Planner.create_plan(attrs)
      assert plan.user == "test_user@example.com"
    end
  end

  describe "create_plan!/1" do
    test "with valid data creates a plan" do
      assert %Plan{} = plan = Planner.create_plan!(@valid_plan_attrs)
      assert plan.prompt == @valid_plan_attrs.prompt
    end

    test "with invalid data raises error" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Planner.create_plan!(@invalid_plan_attrs)
      end
    end
  end

  describe "update_plan/2" do
    test "with valid data updates the plan", %{plan: plan} do
      update_attrs = %{notes: "Updated notes"}

      assert {:ok, %Plan{} = updated_plan} = Planner.update_plan(plan, update_attrs)
      assert updated_plan.notes == "Updated notes"
    end

    test "with invalid data returns error changeset", %{plan: plan} do
      assert {:error, %Ecto.Changeset{}} = Planner.update_plan(plan, %{status: :invalid})
    end
  end

  describe "approve_plan/2" do
    test "transitions plan to approved status", %{plan: plan} do
      assert {:ok, %Plan{} = approved_plan} = Planner.approve_plan(plan)
      assert approved_plan.status == :approved
    end

    test "associates user with approval", %{plan: plan} do
      assert {:ok, %Plan{} = approved_plan} = Planner.approve_plan(plan, "user@example.com")
      assert approved_plan.status == :approved
      assert approved_plan.user == "user@example.com"
    end
  end

  describe "reject_plan/2" do
    test "transitions plan to rejected status", %{plan: plan} do
      assert {:ok, %Plan{} = rejected_plan} = Planner.reject_plan(plan)
      assert rejected_plan.status == :rejected
    end

    test "adds notes to rejection", %{plan: plan} do
      assert {:ok, %Plan{} = rejected_plan} = Planner.reject_plan(plan, "Not appropriate")
      assert rejected_plan.status == :rejected
      assert rejected_plan.notes == "Not appropriate"
    end
  end

  describe "mark_plan_executed/1" do
    test "transitions plan to executed status with timestamp", %{plan: plan} do
      assert {:ok, %Plan{} = executed_plan} = Planner.mark_plan_executed(plan)
      assert executed_plan.status == :executed
      assert executed_plan.executed_at != nil
    end
  end

  describe "mark_plan_error/2" do
    test "transitions plan to error status with error message", %{plan: plan} do
      error_message = "Failed to execute plan"

      assert {:ok, %Plan{} = error_plan} = Planner.mark_plan_error(plan, error_message)
      assert error_plan.status == :error
      assert error_plan.error == error_message
    end
  end

  describe "delete_plan/1" do
    test "deletes the plan", %{plan: plan} do
      assert {:ok, %Plan{}} = Planner.delete_plan(plan)
      assert_raise Ecto.NoResultsError, fn -> Planner.get_plan!(plan.id) end
    end

    test "deletes associated changes", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work.id,
          add: %{descriptive_metadata: %{title: "Updated"}}
        })

      Planner.delete_plan(plan)
      assert Planner.get_plan_change(change.id) == nil
    end
  end

  describe "change_plan/2" do
    test "returns a plan changeset", %{plan: plan} do
      assert %Ecto.Changeset{} = Planner.change_plan(plan)
    end

    test "returns changeset with changes", %{plan: plan} do
      changeset = Planner.change_plan(plan, %{notes: "New notes"})
      assert changeset.changes.notes == "New notes"
    end
  end

  # ========== PlanChange Tests ==========

  describe "list_plan_changes/1" do
    test "returns all changes for a plan", %{plan: plan, work: work} do
      {:ok, _} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      {:ok, _} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      changes = Planner.list_plan_changes(plan.id)
      assert length(changes) == 2
    end

    test "returns empty list when no changes", %{plan: plan} do
      assert Planner.list_plan_changes(plan.id) == []
    end
  end

  describe "list_plan_changes/2" do
    test "filters by status", %{plan: plan, work: work} do
      {:ok, pending} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      {:ok, approved} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      Planner.approve_plan_change(approved)

      pending_changes = Planner.list_plan_changes(plan.id, status: :pending)
      assert length(pending_changes) == 1
      assert hd(pending_changes).id == pending.id
    end

    test "filters by work_id", %{plan: plan} do
      work1 = work_fixture()
      work2 = work_fixture()

      {:ok, change1} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work1.id, add: %{}})

      {:ok, _change2} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work2.id, add: %{}})

      work1_changes = Planner.list_plan_changes(plan.id, work_id: work1.id)
      assert length(work1_changes) == 1
      assert hd(work1_changes).id == change1.id
    end
  end

  describe "get_plan_change!/1" do
    test "returns the change", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert %PlanChange{} = retrieved = Planner.get_plan_change!(change.id)
      assert retrieved.id == change.id
    end

    test "raises if change doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Planner.get_plan_change!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_plan_change/1" do
    test "returns the change", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert %PlanChange{} = retrieved = Planner.get_plan_change(change.id)
      assert retrieved.id == change.id
    end

    test "returns nil if change doesn't exist" do
      assert Planner.get_plan_change(Ecto.UUID.generate()) == nil
    end
  end

  describe "create_plan_change/1" do
    test "with valid add data creates a change", %{plan: plan, work: work} do
      attrs = %{
        plan_id: plan.id,
        work_id: work.id,
        add: %{descriptive_metadata: %{alternate_title: ["El Gato"]}}
      }

      assert {:ok, %PlanChange{} = change} = Planner.create_plan_change(attrs)
      assert change.work_id == work.id
      assert change.add.descriptive_metadata.alternate_title == ["El Gato"]
    end

    test "with valid delete data creates a change", %{plan: plan, work: work} do
      attrs = %{
        plan_id: plan.id,
        work_id: work.id,
        delete: %{
          descriptive_metadata: %{
            subject: [
              %{
                role: %{id: "TOPICAL", scheme: "subject_role"},
                term: %{id: "http://id.loc.gov/authorities/subjects/sh85101196"}
              }
            ]
          }
        }
      }

      assert {:ok, %PlanChange{} = change} = Planner.create_plan_change(attrs)
      assert change.work_id == work.id
      assert [subj] = change.delete.descriptive_metadata.subject
      assert subj.role.id == "TOPICAL"
      assert subj.term.id == "http://id.loc.gov/authorities/subjects/sh85101196"
    end

    test "with valid replace data creates a change", %{plan: plan, work: work} do
      attrs = %{
        plan_id: plan.id,
        work_id: work.id,
        replace: %{descriptive_metadata: %{title: "New Title"}}
      }

      assert {:ok, %PlanChange{} = change} = Planner.create_plan_change(attrs)
      assert change.work_id == work.id
      assert change.replace.descriptive_metadata.title == "New Title"
    end

    test "without required work_id returns error", %{plan: plan} do
      attrs = %{plan_id: plan.id, add: %{}}
      assert {:error, error_message} = Planner.create_plan_change(attrs)
      assert error_message =~ "can't be blank"
    end

    test "without any operation returns error", %{plan: plan, work: work} do
      attrs = %{plan_id: plan.id, work_id: work.id}
      assert {:error, error_message} = Planner.create_plan_change(attrs)
      assert error_message =~ "at least one of add, delete, or replace must be specified"
    end

    test "with invalid plan_id returns humanized error", %{work: work} do
      invalid_plan_id = "nonexistent-plan-id"

      attrs = %{
        plan_id: invalid_plan_id,
        work_id: work.id,
        add: %{descriptive_metadata: %{alternate_title: ["El Gato"]}}
      }

      assert {:error, error_message} = Planner.create_plan_change(attrs)
      assert error_message == "#{invalid_plan_id} is invalid"
    end
  end

  describe "create_plan_changes/1" do
    test "creates multiple changes at once", %{plan: plan} do
      work1 = work_fixture()
      work2 = work_fixture()

      changes_attrs = [
        %{plan_id: plan.id, work_id: work1.id, add: %{descriptive_metadata: %{title: "Updated 1"}}},
        %{plan_id: plan.id, work_id: work2.id, add: %{descriptive_metadata: %{title: "Updated 2"}}}
      ]

      assert {:ok, changes} = Planner.create_plan_changes(changes_attrs)
      assert length(changes) == 2
    end

    test "rolls back on error", %{plan: plan} do
      work1 = work_fixture()

      changes_attrs = [
        %{plan_id: plan.id, work_id: work1.id, add: %{descriptive_metadata: %{title: "Updated"}}},
        %{plan_id: plan.id, work_id: nil, add: %{}}
      ]

      # The transaction will raise an error and rollback
      assert_raise Ecto.InvalidChangesetError, fn ->
        Planner.create_plan_changes(changes_attrs)
      end

      # Verify no changes were persisted
      assert Planner.list_plan_changes(plan.id) == []
    end
  end

  describe "update_plan_change/2" do
    test "updates the change", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert {:ok, updated} = Planner.update_plan_change(change, %{notes: "Reviewed"})
      assert updated.notes == "Reviewed"
    end

    test "with invalid plan_id returns humanized error", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      invalid_plan_id = "invalid-uuid"

      assert {:error, error_message} =
               Planner.update_plan_change(change, %{plan_id: invalid_plan_id})

      assert error_message == "#{invalid_plan_id} is invalid"
    end
  end

  describe "approve_plan_change/2" do
    test "approves the change", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert {:ok, approved} = Planner.approve_plan_change(change, "user@example.com")
      assert approved.status == :approved
      assert approved.user == "user@example.com"
    end
  end

  describe "reject_plan_change/2" do
    test "rejects the change", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert {:ok, rejected} = Planner.reject_plan_change(change, "Not accurate")
      assert rejected.status == :rejected
      assert rejected.notes == "Not accurate"
    end
  end

  describe "mark_plan_change_executed/1" do
    test "marks change as executed", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert {:ok, executed} = Planner.mark_plan_change_executed(change)
      assert executed.status == :executed
      assert executed.executed_at
    end
  end

  describe "mark_plan_change_error/2" do
    test "marks change as error", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert {:ok, error_change} = Planner.mark_plan_change_error(change, "Work not found")
      assert error_change.status == :error
      assert error_change.error == "Work not found"
    end
  end

  describe "delete_plan_change/1" do
    test "deletes the change", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})

      assert {:ok, %PlanChange{}} = Planner.delete_plan_change(change)
      assert Planner.get_plan_change(change.id) == nil
    end
  end

  describe "execute_plan/1" do
    test "executes all approved changes with replace operation", %{plan: plan} do
      work1 = work_fixture()
      work2 = work_fixture()

      {:ok, change1} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work1.id,
          replace: %{descriptive_metadata: %{title: "Updated 1"}}
        })

      {:ok, change2} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work2.id,
          replace: %{descriptive_metadata: %{title: "Updated 2"}}
        })

      Planner.approve_plan_change(change1)
      Planner.approve_plan_change(change2)
      {:ok, plan} = Planner.approve_plan(plan)

      assert {:ok, executed_plan} = Planner.execute_plan(plan)
      assert executed_plan.status == :executed

      # Verify the plan changes were marked as executed
      assert Planner.list_plan_changes(plan.id, status: :executed) |> length() == 2
    end

    test "returns error when plan is not approved", %{plan: plan, work: work} do
      {:ok, change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work.id,
          replace: %{descriptive_metadata: %{title: "Updated"}}
        })

      Planner.approve_plan_change(change)

      # Plan is still pending, even though changes are approved
      assert {:error, "Plan must be approved before execution"} = Planner.execute_plan(plan)
    end

    test "returns error when no approved changes", %{plan: plan, work: work} do
      Planner.create_plan_change(%{plan_id: plan.id, work_id: work.id, add: %{}})
      {:ok, plan} = Planner.approve_plan(plan)

      assert {:error, "No approved changes to execute"} = Planner.execute_plan(plan)
    end
  end

  describe "execute_plan_change/1" do
    test "applies replace change to work", %{plan: plan} do
      work = work_fixture()

      {:ok, change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work.id,
          replace: %{descriptive_metadata: %{title: "New Title"}},
          status: :approved
        })

      assert {:ok, executed_change} = Planner.execute_plan_change(change)
      assert executed_change.status == :executed

      updated_work = Repo.get!(Meadow.Data.Schemas.Work, work.id)
      assert updated_work.descriptive_metadata.title == "New Title"
    end

    test "applies delete change to controlled field", %{plan: plan} do
      # Create a work with subjects
      work =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Test Work",
            subject: [
              %{term: "mock1:result1", role: %{id: "TOPICAL", scheme: "subject_role"}},
              %{term: "mock1:result2", role: %{id: "GEOGRAPHICAL", scheme: "subject_role"}}
            ]
          }
        })

      # Reload to get the full structure as saved in DB
      work = Repo.get!(Meadow.Data.Schemas.Work, work.id)
      [subj_to_delete | _] = work.descriptive_metadata.subject

      # Create a plan change to delete one subject
      # Convert the struct to match what's stored in JSONB by round-tripping through JSON
      subj_as_map =
        subj_to_delete
        |> Jason.encode!()
        |> Jason.decode!(keys: :atoms)

      {:ok, change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work.id,
          delete: %{
            descriptive_metadata: %{
              subject: [subj_as_map]
            }
          },
          status: :approved
        })

      # Execute the change
      assert {:ok, executed_change} = Planner.execute_plan_change(change)
      assert executed_change.status == :executed

      # Verify the subject was deleted
      updated_work = Repo.get!(Meadow.Data.Schemas.Work, work.id)

      assert length(updated_work.descriptive_metadata.subject) == 1

      [remaining_subject] = updated_work.descriptive_metadata.subject
      assert remaining_subject.term.id == "mock1:result2"
      assert remaining_subject.role.id == "GEOGRAPHICAL"
    end

    test "applies add change to uncontrolled date_created field", %{plan: plan} do
      work = work_fixture()

      {:ok, change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work.id,
          add: %{descriptive_metadata: %{date_created: ["1896-11-10"]}},
          status: :approved
        })

      assert {:ok, executed_change} = Planner.execute_plan_change(change)
      assert executed_change.status == :executed

      updated_work = Repo.get!(Meadow.Data.Schemas.Work, work.id)
      assert [%{edtf: "1896-11-10", humanized: humanized}] =
               updated_work.descriptive_metadata.date_created

      assert humanized != nil
    end

    test "marks error when work not found", %{plan: plan} do
      fake_work_id = Ecto.UUID.generate()

      {:ok, change} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: fake_work_id,
          add: %{},
          status: :approved
        })

      assert {:ok, error_change} = Planner.execute_plan_change(change)
      assert error_change.status == :error
      assert error_change.error == "\"Work not found\""
    end
  end

  describe "full workflow integration" do
    test "Spanish translation workflow" do
      # 1. Create plan
      {:ok, plan} =
        Planner.create_plan(%{
          prompt: "Translate titles to Spanish in alternate_title field",
          query: "collection.id:abc-123"
        })

      # 2. Create work-specific changes
      work_a = work_fixture(%{descriptive_metadata: %{title: "The Cat"}})
      work_b = work_fixture(%{descriptive_metadata: %{title: "The House"}})

      {:ok, change_a} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work_a.id,
          add: %{descriptive_metadata: %{alternate_title: ["El Gato"]}}
        })

      {:ok, change_b} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work_b.id,
          add: %{descriptive_metadata: %{alternate_title: ["La Casa"]}}
        })

      # 3. User reviews and approves
      {:ok, plan} = Planner.approve_plan(plan, "curator@example.com")
      {:ok, _} = Planner.approve_plan_change(change_a, "curator@example.com")
      {:ok, _} = Planner.approve_plan_change(change_b, "curator@example.com")

      # 4. Execute plan
      assert {:ok, executed_plan} = Planner.execute_plan(plan)
      assert executed_plan.status == :executed

      # Verify all changes were applied
      assert Planner.list_plan_changes(plan.id, status: :executed) |> length() == 2
    end

    test "Remove extraneous subjects workflow" do
      # 1. Create plan to remove extraneous subjects
      {:ok, plan} =
        Planner.create_plan(%{
          prompt: "Remove extraneous subject headings like 'Photograph' and 'Image'",
          query: "collection.id:test-collection"
        })

      # 2. Create works with both good and extraneous subjects
      work_a =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Photo of Building",
            subject: [
              %{term: "mock1:result1", role: %{id: "TOPICAL", scheme: "subject_role"}},
              %{term: "mock1:result2", role: %{id: "TOPICAL", scheme: "subject_role"}},
              %{term: "mock2:result3", role: %{id: "TOPICAL", scheme: "subject_role"}}
            ]
          }
        })

      work_b =
        work_fixture(%{
          descriptive_metadata: %{
            title: "Image of Person",
            subject: [
              %{term: "mock1:result1", role: %{id: "TOPICAL", scheme: "subject_role"}},
              %{term: "mock1:result2", role: %{id: "TOPICAL", scheme: "subject_role"}}
            ]
          }
        })

      # 3. Reload works to get full DB structure
      work_a = Repo.get!(Meadow.Data.Schemas.Work, work_a.id)
      work_b = Repo.get!(Meadow.Data.Schemas.Work, work_b.id)

      # Find the subjects to delete by ID and convert to maps matching JSONB storage
      [_keep, subj_a_2, subj_a_3] = work_a.descriptive_metadata.subject
      [_keep_b, subj_b_2] = work_b.descriptive_metadata.subject

      subj_a_2_map = subj_a_2 |> Jason.encode!() |> Jason.decode!(keys: :atoms)
      subj_a_3_map = subj_a_3 |> Jason.encode!() |> Jason.decode!(keys: :atoms)
      subj_b_2_map = subj_b_2 |> Jason.encode!() |> Jason.decode!(keys: :atoms)

      # 4. Agent creates deletion changes for extraneous subjects
      # Work A: Delete "Second Result" (mock1:result2) and "Third Result" (mock2:result3)
      {:ok, change_a} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work_a.id,
          delete: %{
            descriptive_metadata: %{
              subject: [subj_a_2_map, subj_a_3_map]
            }
          }
        })

      # Work B: Delete "Second Result" (mock1:result2)
      {:ok, change_b} =
        Planner.create_plan_change(%{
          plan_id: plan.id,
          work_id: work_b.id,
          delete: %{
            descriptive_metadata: %{
              subject: [subj_b_2_map]
            }
          }
        })

      # 5. User reviews and approves
      {:ok, plan} = Planner.approve_plan(plan, "curator@example.com")
      {:ok, _} = Planner.approve_plan_change(change_a, "curator@example.com")
      {:ok, _} = Planner.approve_plan_change(change_b, "curator@example.com")

      # 6. Execute plan
      assert {:ok, executed_plan} = Planner.execute_plan(plan)
      assert executed_plan.status == :executed

      # 7. Verify changes were applied
      updated_work_a = Repo.get!(Meadow.Data.Schemas.Work, work_a.id)
      assert length(updated_work_a.descriptive_metadata.subject) == 1
      [remaining_a] = updated_work_a.descriptive_metadata.subject
      assert remaining_a.term.id == "mock1:result1"
      assert remaining_a.term.label == "First Result"

      updated_work_b = Repo.get!(Meadow.Data.Schemas.Work, work_b.id)
      assert length(updated_work_b.descriptive_metadata.subject) == 1
      [remaining_b] = updated_work_b.descriptive_metadata.subject
      assert remaining_b.term.id == "mock1:result1"
      assert remaining_b.term.label == "First Result"

      # Verify all changes were executed
      assert Planner.list_plan_changes(plan.id, status: :executed) |> length() == 2
    end
  end
end
