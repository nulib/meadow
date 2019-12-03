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

    field :ingest_sheet_progress, :sheet_progress do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ingest.ingest_sheet_progress/3)
    end

    @desc "Get a presigned url to upload an ingest sheet"
    field :presigned_url, :presigned_url do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.get_presigned_url/3)
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

    @desc "Retrieve all audit entries for an object"
    field :audit_trail, list_of(:audit_entry) do
      arg(:object_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.get_audit_trail/3)
    end

    @desc "Get works created for an Ingest Sheet"
    field :ingest_sheet_works, list_of(:work) do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_sheet_works/3)
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
      resolve(&Resolvers.Ingest.create_project/3)
    end

    @desc "Create a new Ingest Sheet for a Project"
    field :create_ingest_sheet, :ingest_sheet do
      arg(:name, non_null(:string))
      arg(:project_id, non_null(:id))
      arg(:filename, non_null(:string))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.create_ingest_sheet/3)
    end

    @desc "Delete a Project"
    field :delete_project, :project do
      arg(:project_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.delete_project/3)
    end

    @desc "Delete an Ingest Sheet"
    field :delete_ingest_sheet, :ingest_sheet do
      arg(:sheet_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.delete_ingest_sheet/3)
    end

    @desc "Approve an Ingest Sheet"
    field :approve_ingest_sheet, :status_message do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.approve_ingest_sheet/3)
    end

    @desc "Kick off Validation of an Ingest Sheet"
    field :validate_ingest_sheet, :status_message do
      arg(:sheet_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.validate_ingest_sheet/3)
    end
  end

  object :ingest_subscriptions do
    @desc "Subscribe to ingest sheet updates for a project"
    field :ingest_sheet_updates_for_project, :ingest_sheet do
      arg(:project_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "sheets:" <> args.project_id}
      end)
    end

    @desc "Subscribe to validation messages for an ingest sheet"
    field :ingest_sheet_update, :ingest_sheet do
      arg(:sheet_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "sheet:" <> args.sheet_id}
      end)
    end

    field :ingest_sheet_progress_update, :sheet_progress do
      arg(:sheet_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "progress:" <> args.sheet_id}
      end)
    end

    field :ingest_sheet_row_update, :ingest_sheet_row do
      arg(:sheet_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: Enum.join(["row", args.sheet_id], ":")}
      end)
    end

    field :ingest_sheet_row_state_update, :ingest_sheet_row do
      arg(:sheet_id, non_null(:id))
      arg(:state, non_null(:state))

      config(fn args, _info ->
        topic = Enum.join(["row", args.sheet_id, args.state], ":")
        {:ok, topic: topic}
      end)
    end

    @desc "Subscribe to audit trail updates for a specific work or file set"
    field :audit_update, :audit_entry do
      arg(:object_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: args.object_id}
      end)
    end

    @desc "Subscribe to audit trail updates for works and file sets"
    field :audit_updates, :audit_entry do
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

  object :project do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :folder, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)

    field :ingest_sheets, list_of(:ingest_sheet), resolve: dataloader(Ingest)
  end

  @desc "Sheet object"
  object :ingest_sheet do
    field :id, non_null(:id)
    field :name, non_null(:string)
    @desc "Overall Status of the Ingest Sheet"
    field :status, :ingest_sheet_status
    field :state, list_of(:sheet_state)
    field :filename, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
    field :project, :project, resolve: dataloader(Ingest)
    @desc "An array of file level error messages"
    field :file_errors, list_of(:string)

    field :progress, :sheet_progress,
      resolve: fn sheet, _, _ ->
        batch({MeadowWeb.Schema.Helpers, :sheet_progress, Integer}, sheet.id, fn batch_results ->
          {:ok, Map.get(batch_results, sheet.id)}
        end)
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
    value(:completed, as: "completed", description: "Ingest Completed")
    value(:deleted, as: "deleted", description: "Ingest Sheet deleted")
  end

  @desc "states: PENDING, PASS or FAIL"
  enum :state do
    value(:pending, as: "pending")
    value(:pass, as: "pass")
    value(:fail, as: "fail")
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
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)

    field :ingest_sheets, list_of(:ingest_sheet), resolve: dataloader(Ingest)
  end

  object :ingest_sheet_row do
    field :ingest_sheet, :ingest_sheet, resolve: dataloader(Ingest)
    field :row, non_null(:integer)
    field :fields, list_of(:field)
    field :errors, list_of(:error)
    field :state, :state
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

  object :sheet_progress do
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
  object :audit_entry do
    @desc "The ID of the Work or FileSet target of the action"
    field :object_id, non_null(:string)
    @desc "The module name of the action"
    field :action, :string
    @desc "The most recent outcome of the action"
    field :outcome, :action_outcome
    @desc "Additional details regarding the success or failure of the action"
    field :notes, :string
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
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
