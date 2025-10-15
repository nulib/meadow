defmodule Meadow.Data.Schemas.PlanChangeTest do
  use Meadow.DataCase
  alias Meadow.Data.Schemas.{Plan, PlanChange}

  setup do
    {:ok, plan} =
      %Plan{}
      |> Plan.changeset(%{
        prompt: "Translate titles to Spanish",
        query: "collection.id:abc-123"
      })
      |> Repo.insert()

    work = work_fixture()
    {:ok, plan: plan, work: work}
  end

  @valid_attrs %{
    work_id: nil,
    add: %{
      descriptive_metadata: %{
        subject: [
          %{
            role: %{id: "TOPICAL", scheme: "subject_role"},
            term: %{id: "http://id.loc.gov/authorities/subjects/sh85141086"}
          }
        ]
      }
    }
  }

  @invalid_attrs %{work_id: nil, add: nil, delete: nil, replace: nil}

  describe "changeset/2" do
    test "with valid attributes", %{plan: plan, work: work} do
      attrs = Map.merge(@valid_attrs, %{plan_id: plan.id, work_id: work.id})
      changeset = PlanChange.changeset(%PlanChange{}, attrs)
      assert changeset.valid?
    end

    test "without required work_id", %{plan: plan} do
      attrs = Map.merge(@invalid_attrs, %{plan_id: plan.id})
      changeset = PlanChange.changeset(%PlanChange{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).work_id
    end

    test "without any operation", %{plan: plan, work: work} do
      attrs = %{plan_id: plan.id, work_id: work.id}
      changeset = PlanChange.changeset(%PlanChange{}, attrs)
      refute changeset.valid?

      assert "at least one of add, delete, or replace must be specified" in errors_on(changeset).add
    end

    test "validates add is a map", %{plan: plan, work: work} do
      attrs = %{plan_id: plan.id, work_id: work.id, add: "not a map"}
      changeset = PlanChange.changeset(%PlanChange{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).add
    end

    test "validates status is in allowed values", %{plan: plan, work: work} do
      attrs = Map.merge(@valid_attrs, %{plan_id: plan.id, work_id: work.id, status: :invalid})
      changeset = PlanChange.changeset(%PlanChange{}, attrs)
      refute changeset.valid?
    end

    test "allows valid status values", %{plan: plan, work: work} do
      for status <- [:pending, :proposed, :approved, :rejected, :completed, :error] do
        attrs = Map.merge(@valid_attrs, %{plan_id: plan.id, work_id: work.id, status: status})
        changeset = PlanChange.changeset(%PlanChange{}, attrs)
        assert changeset.valid?
      end
    end
  end

  describe "approve/2" do
    test "transitions to approved status", %{plan: plan, work: work} do
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work.id,
          add: @valid_attrs.add
        })
        |> Repo.insert()

      changeset = PlanChange.approve(change, "user@example.com")

      assert changeset.valid?
      assert get_change(changeset, :status) == :approved
      assert get_change(changeset, :user) == "user@example.com"
    end
  end

  describe "reject/2" do
    test "transitions to rejected status with notes", %{plan: plan, work: work} do
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work.id,
          add: @valid_attrs.add
        })
        |> Repo.insert()

      changeset = PlanChange.reject(change, "Translation is incorrect")

      assert changeset.valid?
      assert get_change(changeset, :status) == :rejected
      assert get_change(changeset, :notes) == "Translation is incorrect"
    end
  end

  describe "mark_completed/1" do
    test "transitions to completed status with timestamp", %{plan: plan, work: work} do
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work.id,
          add: @valid_attrs.add,
          status: :approved
        })
        |> Repo.insert()

      changeset = PlanChange.mark_completed(change)

      assert changeset.valid?
      assert get_change(changeset, :status) == :completed
      assert get_change(changeset, :completed_at)
    end
  end

  describe "mark_error/2" do
    test "transitions to error status with error message", %{plan: plan, work: work} do
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work.id,
          add: @valid_attrs.add,
          status: :approved
        })
        |> Repo.insert()

      changeset = PlanChange.mark_error(change, "Work not found")

      assert changeset.valid?
      assert get_change(changeset, :status) == :error
      assert get_change(changeset, :error) == "Work not found"
    end
  end

  describe "integration scenarios" do
    test "Spanish translation for work A", %{plan: plan} do
      work_a = work_fixture(%{descriptive_metadata: %{title: "The Cat"}})

      # Agent creates change with Spanish translation
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work_a.id,
          add: %{
            descriptive_metadata: %{alternate_title: ["El Gato"]}
          },
          status: :proposed
        })
        |> Repo.insert()

      assert change.status == :proposed
      assert change.add.descriptive_metadata.alternate_title == ["El Gato"]

      # User approves
      {:ok, approved} =
        change
        |> PlanChange.approve("user@example.com")
        |> Repo.update()

      assert approved.status == :approved
      assert approved.user == "user@example.com"

      # System applies
      {:ok, completed} =
        approved
        |> PlanChange.mark_completed()
        |> Repo.update()

      assert completed.status == :completed
      assert completed.completed_at
    end

    test "LCNAF contributor assignment", %{plan: plan} do
      work = work_fixture(%{descriptive_metadata: %{title: "Ansel Adams Photography"}})

      # Agent creates change with LOC authority
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work.id,
          add: %{
            descriptive_metadata: %{
              contributor: [
                %{
                  role: %{id: "pht", scheme: "marc_relator"},
                  term: %{
                    id: "http://id.loc.gov/authorities/names/n79127000",
                    label: "Adams, Ansel, 1902-1984"
                  }
                }
              ]
            }
          }
        })
        |> Repo.insert()

      assert [contrib] = change.add.descriptive_metadata.contributor
      assert contrib.role.id == "pht"
      assert contrib.term.id == "http://id.loc.gov/authorities/names/n79127000"
      assert contrib.term.label == "Adams, Ansel, 1902-1984"

      # User approves and applies
      {:ok, approved} =
        change
        |> PlanChange.approve("curator@example.com")
        |> Repo.update()

      {:ok, completed} =
        approved
        |> PlanChange.mark_completed()
        |> Repo.update()

      assert completed.status == :completed
    end

    test "rejected change workflow", %{plan: plan, work: work} do
      # Agent creates change
      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work.id,
          add: %{
            descriptive_metadata: %{alternate_title: ["Wrong Translation"]}
          }
        })
        |> Repo.insert()

      # User rejects with notes
      {:ok, rejected} =
        change
        |> PlanChange.reject("This translation is inaccurate")
        |> Repo.update()

      assert rejected.status == :rejected
      assert rejected.notes == "This translation is inaccurate"
    end

    test "execution error workflow", %{plan: plan} do
      # Create change for non-existent work
      fake_work_id = Ecto.UUID.generate()

      {:ok, change} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: fake_work_id,
          add: @valid_attrs.add,
          status: :approved
        })
        |> Repo.insert()

      # Mark as error when execution fails
      {:ok, error_change} =
        change
        |> PlanChange.mark_error("Work #{fake_work_id} not found")
        |> Repo.update()

      assert error_change.status == :error
      assert error_change.error =~ "not found"
    end

    test "multiple changes for the same plan", %{plan: plan} do
      work_a = work_fixture(%{descriptive_metadata: %{title: "The Cat"}})
      work_b = work_fixture(%{descriptive_metadata: %{title: "The House"}})
      work_c = work_fixture(%{descriptive_metadata: %{title: "The Dogs"}})

      # Agent creates multiple changes
      {:ok, change_a} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work_a.id,
          add: %{descriptive_metadata: %{alternate_title: ["El Gato"]}}
        })
        |> Repo.insert()

      {:ok, change_b} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work_b.id,
          add: %{descriptive_metadata: %{alternate_title: ["La Casa"]}}
        })
        |> Repo.insert()

      {:ok, change_c} =
        %PlanChange{}
        |> PlanChange.changeset(%{
          plan_id: plan.id,
          work_id: work_c.id,
          add: %{descriptive_metadata: %{alternate_title: ["Los Perros"]}}
        })
        |> Repo.insert()

      # Verify all changes belong to the same plan
      changes = Repo.all(from(c in PlanChange, where: c.plan_id == ^plan.id))
      assert length(changes) == 3
      assert Enum.all?(changes, &(&1.plan_id == plan.id))

      # User can approve/reject individually
      {:ok, _} = PlanChange.approve(change_a, "user@example.com") |> Repo.update()
      {:ok, _} = PlanChange.approve(change_b, "user@example.com") |> Repo.update()
      {:ok, _} = PlanChange.reject(change_c, "Needs review") |> Repo.update()

      approved_count =
        Repo.aggregate(
          from(c in PlanChange, where: c.plan_id == ^plan.id and c.status == :approved),
          :count
        )

      assert approved_count == 2
    end
  end
end
