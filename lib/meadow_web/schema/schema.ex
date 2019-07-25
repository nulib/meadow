defmodule MeadowWeb.Schema.Schema do
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)

  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 3]

  alias MeadowWeb.Resolvers
  alias Meadow.Ingest

  query do
    @desc "Get a list of projects"
    field :projects, list_of(:project) do
      arg(:limit, :integer, default_value: 100)
      arg(:order, type: :sort_order, default_value: :desc)
      resolve(&MeadowWeb.Resolvers.Ingest.projects/3)
    end

    @desc "Get a project by its id"
    field :project, :project do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ingest.project/3)
    end

    @desc "Get an ingest job by its id"
    field :ingest_job, :ingest_job do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ingest.ingest_job/3)
    end

    @desc "Get a presigned url to upload an inventory sheet"
    field :presigned_url, :presigned_url do
      resolve(&Resolvers.Ingest.get_presigned_url/3)
    end
  end

  mutation do
    @desc "Create a new Ingest Project"
    field :create_project, :project do
      arg(:title, non_null(:string))
      resolve(&Resolvers.Ingest.create_project/3)
    end

    @desc "Create a new Ingest Job for a Project"
    field :create_ingest_job, :ingest_job do
      arg(:name, non_null(:string))
      arg(:project_id, non_null(:id))
      arg(:filename, non_null(:string))
      resolve(&Resolvers.Ingest.create_ingest_job/3)
    end

    @desc "Delete a Project"
    field :delete_project, :project do
      arg(:project_id, non_null(:id))
      resolve(&Resolvers.Ingest.delete_project/3)
    end

    @desc "Delete an Ingest Job"
    field :delete_ingest_job, :ingest_job do
      arg(:ingest_job_id, non_null(:id))
      resolve(&Resolvers.Ingest.delete_ingest_job/3)
    end

    @desc "Change the state of an ingest_job"
    field :change_ingest_job_state, :ingest_job do
      arg(:ingest_job_id, non_null(:id))
      arg(:state, non_null(:string))
      resolve(&Resolvers.Ingest.change_ingest_job_state/3)
    end
  end

  subscription do
    @desc "Subscribe to a state change for an Ingest Job"
    field :ingest_job_change, :ingest_job do
      arg(:ingest_job_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: args.ingest_job_id}
      end)
    end
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
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
    field :state, non_null(:string)
    field :filename, non_null(:string)
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
    field :project, :project, resolve: dataloader(Ingest)
  end

  object :presigned_url do
    field :url, non_null(:string)
  end

  object :validation_result do
    field :message, non_null(:string)
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
