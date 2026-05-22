defmodule MeadowWeb.Schema.EvalTypes do
  @moduledoc "Absinthe types and resolvers for the evals feature."

  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Evals
  alias MeadowWeb.Schema.Middleware

  # ---------------------------------------------------------------------------
  # Scalar / enum types
  # ---------------------------------------------------------------------------

  enum :eval_run_status do
    value(:pending)
    value(:running)
    value(:complete)
    value(:errored)
    value(:cancelled)
  end

  enum :eval_trial_status do
    value(:pending)
    value(:running)
    value(:complete)
    value(:errored)
    value(:skipped)
  end

  enum :eval_manual_score do
    value(:unscored)
    value(:good)
    value(:bad)
  end

  # ---------------------------------------------------------------------------
  # Object types
  # ---------------------------------------------------------------------------

  object :eval_query_type do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:description, :string)
    field(:query_json, :json)
    field(:author, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :eval_prompt_version do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:system_prompt, non_null(:string))
    field(:user_prompt_template, non_null(:string))

    field :subject_prompt, :string do
      resolve(fn prompt_version, _, _ ->
        {:ok, prompt_version.subject_prompt || Meadow.Evals.default_subject_prompt()}
      end)
    end

    field :description_prompt, :string do
      resolve(fn prompt_version, _, _ ->
        {:ok, prompt_version.description_prompt || Meadow.Evals.default_description_prompt()}
      end)
    end

    field(:parent_version_id, :id)
    field(:author, :string)
    field(:change_notes, :string)
    field(:archived, non_null(:boolean))
    field(:inserted_at, :datetime)
  end

  object :eval_set_member do
    field(:id, non_null(:id))
    field(:work_id, non_null(:id))
    field(:accession_number, :string)
    field(:representative_file_set_id, :id)
    field(:ground_truth, :json)
  end

  object :eval_set do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:description, :string)
    field(:query_id, :id)
    field(:query_snapshot, :json)
    field(:work_count, :integer)
    field(:author, :string)
    field(:inserted_at, :datetime)
    field(:eval_set_members, list_of(:eval_set_member))
  end

  object :eval_run_summary do
    field(:total, :integer)
    field(:complete, :integer)
    field(:errored, :integer)
    field(:pending, :integer)
    field(:running, :integer)
    field(:manual_good, :integer)
    field(:manual_bad, :integer)
    field(:mean_description_judge_score, :float)
    field(:mean_subjects_judge_score, :float)
  end

  object :eval_run do
    field(:id, non_null(:id))
    field(:name, :string)
    field(:eval_set_id, non_null(:id))
    field(:prompt_version_id, non_null(:id))
    field(:trials_per_work, non_null(:integer))
    field(:concurrency, :integer)
    field(:status, :eval_run_status)
    field(:started_at, :datetime)
    field(:completed_at, :datetime)
    field(:author, :string)
    field(:error, :string)
    field(:inserted_at, :datetime)
    field(:eval_set, :eval_set)
    field(:prompt_version, :eval_prompt_version)
    field(:eval_trials, list_of(:eval_trial))

    field :summary, :eval_run_summary do
      resolve(&Evals.run_summary/3)
    end
  end

  object :eval_trial do
    field(:id, non_null(:id))
    field(:eval_run_id, non_null(:id))
    field(:work_id, non_null(:id))
    field(:trial_index, non_null(:integer))
    field(:status, :eval_trial_status)
    field(:agent_output, :json)
    field(:transcript, :json)
    field(:description_judge_score, :float)
    field(:subjects_judge_score, :float)
    field(:judge_rationale, :string)
    field(:manual_score, :eval_manual_score)
    field(:manual_notes, :string)
    field(:manual_scored_by, :string)
    field(:manual_scored_at, :datetime)
    field(:error, :string)
    field(:duration_ms, :integer)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  object :eval_queries do
    @desc "List all saved eval queries"
    field :eval_query_list, list_of(:eval_query_type) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.list_eval_queries/3)
    end

    @desc "Get the environment-default eval query"
    field :default_eval_query, :eval_query_type do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.default_eval_query/3)
    end

    @desc "List all prompt versions"
    field :eval_prompt_versions, list_of(:eval_prompt_version) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.list_prompt_versions/3)
    end

    @desc "List all eval sets"
    field :eval_sets, list_of(:eval_set) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.list_eval_sets/3)
    end

    @desc "Get a single eval set with members"
    field :eval_set, :eval_set do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.get_eval_set/3)
    end

    @desc "List eval runs (most recent first)"
    field :eval_runs, list_of(:eval_run) do
      arg(:limit, :integer)
      arg(:offset, :integer)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.list_runs/3)
    end

    @desc "Get a single eval run with trials"
    field :eval_run, :eval_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.get_run/3)
    end
  end

  # ---------------------------------------------------------------------------
  # Mutations
  # ---------------------------------------------------------------------------

  object :eval_mutations do
    @desc "Create a saved eval query (Superuser only)"
    field :create_eval_query, :eval_query_type do
      arg(:name, non_null(:string))
      arg(:description, :string)
      arg(:query_json, non_null(:json))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Superuser")
      resolve(&Evals.create_eval_query/3)
    end

    @desc "Update a saved eval query (Superuser only)"
    field :update_eval_query, :eval_query_type do
      arg(:id, non_null(:id))
      arg(:name, :string)
      arg(:description, :string)
      arg(:query_json, :json)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Superuser")
      resolve(&Evals.update_eval_query/3)
    end

    @desc "Delete a saved eval query (Superuser only)"
    field :delete_eval_query, :eval_query_type do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Superuser")
      resolve(&Evals.delete_eval_query/3)
    end

    @desc "Create a new prompt version"
    field :create_eval_prompt_version, :eval_prompt_version do
      arg(:name, non_null(:string))
      arg(:subject_prompt, non_null(:string))
      arg(:description_prompt, non_null(:string))
      arg(:system_prompt, :string)
      arg(:user_prompt_template, :string)
      arg(:parent_version_id, :id)
      arg(:change_notes, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.create_prompt_version/3)
    end

    @desc "Archive a prompt version"
    field :archive_eval_prompt_version, :eval_prompt_version do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.archive_prompt_version/3)
    end

    @desc "Create an eval set by materializing works from a saved query"
    field :create_eval_set, :eval_set do
      arg(:query_id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:description, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.create_eval_set/3)
    end

    @desc "Create an eval set from a pasted list of work IDs"
    field :create_eval_set_from_work_ids, :eval_set do
      arg(:work_ids, non_null(list_of(non_null(:id))))
      arg(:name, non_null(:string))
      arg(:description, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.create_eval_set_from_work_ids/3)
    end

    @desc "Create and start an eval run"
    field :create_eval_run, :eval_run do
      arg(:eval_set_id, non_null(:id))
      arg(:prompt_version_id, non_null(:id))
      arg(:name, :string)
      arg(:trials_per_work, :integer)
      arg(:concurrency, :integer)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.create_run/3)
    end

    @desc "Cancel a running eval run"
    field :cancel_eval_run, :eval_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.cancel_run/3)
    end

    @desc "Set manual score for an eval trial"
    field :score_eval_trial, :eval_trial do
      arg(:id, non_null(:id))
      arg(:score, non_null(:eval_manual_score))
      arg(:notes, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.score_trial/3)
    end

    @desc "Clear manual score for an eval trial"
    field :clear_eval_trial_score, :eval_trial do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Evals.clear_trial_score/3)
    end
  end
end
