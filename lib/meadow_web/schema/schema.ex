defmodule MeadowWeb.Schema.Schema do
  @moduledoc """
  Absinthe Schema for MeadowWeb

  """
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(MeadowWeb.Schema.Types.Json)

  import Absinthe.Resolution.Helpers, only: [batch: 3, dataloader: 1]
  alias Meadow.Ingest
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  query do
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

    @desc "Get an ingest job by its id"
    field :ingest_job, :ingest_job do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_job/3)
    end

    field :ingest_job_progress, :job_progress do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ingest.ingest_job_progress/3)
    end

    @desc "Get a presigned url to upload an inventory sheet"
    field :presigned_url, :presigned_url do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.get_presigned_url/3)
    end

    @desc "Get rows for an Inventory Sheet"
    field :ingest_job_rows, list_of(:ingest_job_row) do
      arg(:job_id, non_null(:id))
      arg(:state, list_of(:state))
      arg(:start, :integer)
      arg(:limit, :integer)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.ingest_job_rows/3)
    end

    @desc "Get the currently signed-in user"
    field :me, :user do
      resolve(&Resolvers.Accounts.me/3)
    end
  end

  mutation do
    @desc "Create a new Ingest Project"
    field :create_project, :project do
      arg(:title, non_null(:string))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.create_project/3)
    end

    @desc "Create a new Ingest Job for a Project"
    field :create_ingest_job, :ingest_job do
      arg(:name, non_null(:string))
      arg(:project_id, non_null(:id))
      arg(:filename, non_null(:string))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.create_ingest_job/3)
    end

    @desc "Delete a Project"
    field :delete_project, :project do
      arg(:project_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.delete_project/3)
    end

    @desc "Delete an Ingest Job"
    field :delete_ingest_job, :ingest_job do
      arg(:ingest_job_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.delete_ingest_job/3)
    end

    @desc "Validate an Ingest Job"
    field :validate_ingest_job, :status_message do
      arg(:ingest_job_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.validate_ingest_job/3)
    end
  end

  subscription do
    @desc "Subscribe to validation messages for an ingest job"
    field :ingest_job_update, :ingest_job do
      arg(:job_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "job:" <> args.job_id}
      end)
    end

    field :ingest_job_progress_update, :job_progress do
      arg(:job_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "progress:" <> args.job_id}
      end)
    end

    field :ingest_job_row_update, :ingest_job_row do
      arg(:job_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: Enum.join(["row", args.job_id], ":")}
      end)
    end

    field :ingest_job_row_state_update, :ingest_job_row do
      arg(:job_id, non_null(:id))
      arg(:state, non_null(:state))

      config(fn args, _info ->
        topic = Enum.join(["row", args.job_id, args.state], ":")
        {:ok, topic: topic}
      end)
    end
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end

  enum :state do
    value(:pending, as: "pending")
    value(:pass, as: "pass")
    value(:fail, as: "fail")
  end

  object :project do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :folder, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)

    field :ingest_jobs, list_of(:ingest_job), resolve: dataloader(Ingest)
  end

  object :ingest_job do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :state, list_of(:job_state)
    field :filename, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
    field :project, :project, resolve: dataloader(Ingest)

    field :progress, :job_progress,
      resolve: fn job, _, _ ->
        batch({MeadowWeb.Schema.Helpers, :job_progress, Integer}, job.id, fn batch_results ->
          {:ok, Map.get(batch_results, job.id)}
        end)
      end

    field :ingest_rows, list_of(:ingest_job_row), resolve: dataloader(Ingest)
  end

  object :job_progress do
    field :states, list_of(:state_count)
    field :total, non_null(:integer)
    field :percent_complete, non_null(:float)
  end

  object :presigned_url do
    field :url, non_null(:string)
  end

  object :status_message do
    field :message, non_null(:string)
  end

  object :job_state do
    field :name, :string
    field :state, non_null(:state)
  end

  object :field do
    field :header, non_null(:string)
    field :value, non_null(:string)
  end

  object :error do
    field :field, non_null(:string)
    field :message, non_null(:string)
  end

  object :state_count do
    field :state, non_null(:state)
    field :count, non_null(:integer)
  end

  object :ingest_job_row do
    field :ingest_job, :ingest_job, resolve: dataloader(Ingest)
    field :row, non_null(:integer)
    field :fields, list_of(:field)
    field :errors, list_of(:error)
    field :state, :state
  end

  object :user do
    field :username, non_null(:string)
    field :email, :string
    field :display_name, :string
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Ingest, Ingest.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
