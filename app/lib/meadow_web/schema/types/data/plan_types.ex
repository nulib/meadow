defmodule MeadowWeb.Schema.Data.PlanTypes do
  @moduledoc """
  Absinthe Schema for Plan functionality

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data.Plans
  alias MeadowWeb.Schema.Middleware

  object :plan_queries do
    @desc "Get a plan by id"
    field :plan, :plan do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.plan/3)
    end

    @desc "Get all changes for a plan"
    field :plan_changes, list_of(:plan_change) do
      arg(:plan_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.plan_changes/3)
    end

    @desc "Get a plan change by id"
    field :plan_change, :plan_change do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.plan_change/3)
    end
  end

  object :plan_mutations do
    @desc "Update plan status (approve or reject)"
    field :update_plan_status, :plan do
      arg(:id, non_null(:id))
      arg(:status, non_null(:plan_status))
      arg(:notes, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.update_plan_status/3)
    end

    @desc "Update plan change status (approve or reject)"
    field :update_plan_change_status, :plan_change do
      arg(:id, non_null(:id))
      arg(:status, non_null(:plan_status))
      arg(:notes, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.update_plan_change_status/3)
    end

    @desc "Update all proposed plan change statuses (approve or reject)"
    field :update_proposed_plan_change_statuses, list_of(:plan_change) do
      arg(:plan_id, non_null(:id))
      arg(:status, non_null(:plan_status))
      arg(:notes, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.update_proposed_plan_change_statuses/3)
    end

    @desc "Apply an approved plan to works"
    field :apply_plan, :plan do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Plans.apply_plan/3)
    end
  end

  object :plan_subscriptions do
    field :plan_updated, :plan do
      arg(:plan_id, non_null(:id))

      config(fn args, _ ->
        {:ok, topic: "plan:#{args.plan_id}"}
      end)
    end

    field :plan_changes_updated, :plan_change_update do
      arg(:plan_id, non_null(:id))

      config(fn args, _ ->
        {:ok, topic: "plan_change:#{args.plan_id}"}
      end)
    end
  end

  #
  # Object Types
  #

  @desc "Fields for a `plan` object"
  object :plan do
    field(:id, :id)
    field(:prompt, :string)
    field(:query, :string)
    field(:status, :plan_status)
    field(:user, :string)
    field(:notes, :string)
    field(:completed_at, :datetime)
    field(:error, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  @desc "Fields for a `plan_change` object"
  object :plan_change do
    field(:id, :id)
    field(:plan_id, :id)
    field(:work_id, :id)
    field(:add, :json)
    field(:delete, :json)
    field(:replace, :json)
    field(:status, :plan_status)
    field(:user, :string)
    field(:notes, :string)
    field(:completed_at, :datetime)
    field(:error, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  @desc "Plan status values"
  enum :plan_status do
    value(:pending, as: :pending, description: "Plan created")
    value(:proposed, as: :proposed, description: "Pending review")
    value(:approved, as: :approved, description: "Approved, will be applied")
    value(:rejected, as: :rejected, description: "Rejected, will not be applied")
    value(:completed, as: :completed, description: "Successfully applied")
    value(:error, as: :error, description: "Failed to apply")
  end

  object :plan_change_update do
    field(:plan_id, non_null(:id), description: "The plan ID")
    field(:plan_change, :plan_change, description: "The updated plan change")
    field(:action, non_null(:string), description: "The action that occurred: 'created', 'updated', 'deleted'")
  end
end
