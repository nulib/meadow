defmodule MeadowWeb.Schema.IngestTypes do
  @moduledoc """
  Absinthe Schema for IngestTypes

  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [batch: 3, dataloader: 1]
  alias Meadow.Ingest
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :ingest_queries do
    @desc "Get a list of projects"
    field :projects, list_of(:project) do
      arg(:limit, :integer, default_value: 100)
      arg(:order, type: :sort_order, default_value: :desc)
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Ingest.projects/3)
    end

    @desc "Search for projects by title"
    field :projects_search, list_of(:project) do
      arg(:query, non_null(:string))
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Ingest.search_projects/3)
    end

    @desc "Get a project by its id"
    field :project, :project do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.project/3)
    end

    @desc "Get an ingest sheet by its id"
    field :ingest_sheet, :ingest_sheet do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_sheet/3)
    end

    @desc "Get the validation status for an ingest sheet"
    field :ingest_sheet_validation_progress, :validation_progress do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ingest.ingest_sheet_validation_progress/3)
    end

    @desc "Get rows for an Ingest Sheet"
    field :ingest_sheet_rows, list_of(:ingest_sheet_row) do
      arg(:sheet_id, non_null(:id))
      arg(:state, list_of(:state))
      arg(:start, :integer)
      arg(:limit, :integer)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_sheet_rows/3)
    end

    @desc "Retrieve all action states for an object"
    field :action_states, list_of(:action_state) do
      arg(:object_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.get_action_states/3)
    end

    @desc "Get works created for an Ingest Sheet"
    field :ingest_sheet_works, list_of(:work) do
      arg(:id, non_null(:id))
      arg(:limit, :integer)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_sheet_works/3)
    end

    @desc "Get total number of works and file sets created for an Ingest Sheet"
    field :ingest_sheet_work_count, :ingest_sheet_counts do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_sheet_counts/3)
    end

    @desc "Get errors for completed ingest sheet"
    field :ingest_sheet_errors, list_of(:ingest_sheet_error) do
      @desc "The ID of `Sheet` (can be anything)"
      arg(:id, type: non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_sheet_errors/3)
    end
  end

  object :ingest_mutations do
    @desc "Create a new Ingest Project"
    field :create_project, :project do
      arg(:title, non_null(:string))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Ingest.create_project/3)
    end

    @desc "Update an Ingest Project"
    field :update_project, :project do
      arg(:id, non_null(:id))
      arg(:title, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Ingest.update_project/3)
    end

    @desc "Create a new Ingest Sheet for a Project"
    field :create_ingest_sheet, :ingest_sheet do
      arg(:title, non_null(:string))
      arg(:project_id, non_null(:id))
      arg(:filename, non_null(:string))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Ingest.create_ingest_sheet/3)
    end

    @desc "Delete a Project"
    field :delete_project, :project do
      arg(:project_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Ingest.delete_project/3)
    end

    @desc "Delete an Ingest Sheet"
    field :delete_ingest_sheet, :ingest_sheet do
      arg(:sheet_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Ingest.delete_ingest_sheet/3)
    end

    @desc "Kick off Validation of an Ingest Sheet"
    field :validate_ingest_sheet, :status_message do
      arg(:sheet_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Ingest.validate_ingest_sheet/3)
    end
  end

  object :ingest_subscriptions do
    @desc "Subscribe to ingest sheet updates for a specific project"
    field :ingest_sheet_updates_for_project, :ingest_sheet do
      arg(:project_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "sheets:" <> args.project_id}
      end)
    end

    @desc "Subscribe to updates for an ingest sheet"
    field :ingest_sheet_update, :ingest_sheet do
      arg(:sheet_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "sheet:" <> args.sheet_id}
      end)
    end

    @desc "Subscribe to action state updates for a specific work or file set"
    field :action_update, :action_state do
      arg(:object_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: args.object_id}
      end)
    end

    @desc "Subscribe to action state updates for works and file sets"
    field :action_updates, :action_state do
      config(fn _args, _info ->
        {:ok, topic: :all}
      end)
    end

    @desc "Subscribe to work creation progress notifications for an ingest sheet"
    field :ingest_progress, :work_ingest_progress do
      arg(:sheet_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: args.sheet_id}
      end)
    end
  end

  @desc "Sheet object"
  object :ingest_sheet do
    field :id, non_null(:id)
    field :title, non_null(:string)
    @desc "Overall Status of the Ingest Sheet"
    field :status, :ingest_sheet_status
    field :state, list_of(:sheet_state)
    field :filename, non_null(:string)
    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
    field :project, :project, resolve: dataloader(Ingest)
    @desc "An array of file level error messages"
    field :file_errors, list_of(:string)

    field :validation_progress, :validation_progress,
      resolve: fn sheet, _, _ ->
        batch(
          {MeadowWeb.Schema.Helpers, :validation_progress, Integer},
          sheet.id,
          fn batch_results ->
            {:ok, Map.get(batch_results, sheet.id)}
          end
        )
      end

    field :ingest_sheet_rows, list_of(:ingest_sheet_row), resolve: dataloader(Ingest)
  end

  @desc "Overall status of the Ingest Sheet"
  enum :ingest_sheet_status do
    value(:uploaded, as: "uploaded", description: "Uploaded, validation in progress")
    value(:file_fail, as: "file_fail", description: "Errors validating csv file")
    value(:row_fail, as: "row_fail", description: "Errors in content rows")
    value(:valid, as: "valid", description: "Passes validation")
    value(:approved, as: "approved", description: "Approved, ingest in progress")
    value(:completed, as: "completed", description: "Ingest completed")
    value(:completed_error, as: "completed_error", description: "Ingest completed (with errors)")
    value(:deleted, as: "deleted", description: "Ingest Sheet deleted")
  end

  @desc "Action outcomes"
  enum :action_outcome do
    value(:waiting, as: "waiting", description: "Action is pending but not yet started")
    value(:started, as: "started", description: "Action has been initiated but not yet completed")
    value(:ok, as: "ok", description: "Action completed successfully")
    value(:error, as: "error", description: "Action failed; see notes field for details")
    value(:skipped, as: "skipped", description: "Action skipped due to upstream error(s)")
  end

  @desc "an Ingest Project"
  object :project do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :folder, non_null(:string)
    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)

    field :ingest_sheets, list_of(:ingest_sheet), resolve: dataloader(OrderedIngestSheets)
  end

  object :ingest_sheet_row do
    field :ingest_sheet, :ingest_sheet, resolve: dataloader(Ingest)
    field :row, non_null(:integer)
    field :fields, list_of(:field)
    field :errors, list_of(:error)
    field :state, :state
  end

  @desc "Fields for an ingest sheet's works and file sets count"
  object :ingest_sheet_counts do
    field :total_works, :integer
    field :total_file_sets, :integer
    field :pass, :integer
    field :fail, :integer
  end

  @desc "Object that tracks Sheet state"
  object :sheet_state do
    @desc "name: file, rows, or overall"
    field :name, :string
    field :state, non_null(:state)
  end

  @desc "states: PENDING, PASS or FAIL"
  enum :state do
    value(:pending, as: "pending")
    value(:pass, as: "pass")
    value(:fail, as: "fail")
  end

  object :validation_progress do
    field :states, list_of(:state_count)
    field :total, non_null(:integer)
    field :percent_complete, non_null(:float)
  end

  object :state_count do
    field :state, non_null(:state)
    field :count, non_null(:integer)
  end

  object :ingest_sheet_error do
    field :row_number, :integer
    field :accession_number, :string
    field :work_accession_number, :string
    field :role, :string
    field :description, :string
    field :filename, :string
    field :action, non_null(:string)
    field :outcome, non_null(:action_outcome)
    field :errors, :string
  end

  @desc "The state of a single action within a pipeline"
  object :action_state do
    @desc "The ID of the Work or FileSet target of the action"
    field :object_id, non_null(:string)
    @desc "The module name of the action"
    field :action, :string
    @desc "The most recent outcome of the action"
    field :outcome, :action_outcome
    @desc "Additional details regarding the success or failure of the action"
    field :notes, :string
    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  @desc """
  A summary progress report on the ingest of a single Ingest Sheet. NOTE: This
  does not indicate success, only done-ness.
  """
  object :work_ingest_progress do
    @desc "The ID of the Ingest Sheet in progress"
    field :sheet_id, non_null(:id)
    @desc "The total number of FileSets attached to the Ingest Sheet"
    field :total_file_sets, non_null(:integer)
    @desc "The number of FileSets that have reached OK or ERROR state"
    field :completed_file_sets, non_null(:integer)
    @desc "The total number of actions required to complete the ingest"
    field :total_actions, non_null(:integer)
    @desc "The number of actions that have reached OK or ERROR state"
    field :completed_actions, non_null(:integer)
    @desc "The percentage of actions that have reached OK or ERROR state"
    field :percent_complete, non_null(:float)
  end
end
