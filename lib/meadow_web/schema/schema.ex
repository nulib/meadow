defmodule MeadowWeb.Schema do
  @moduledoc """
  Absinthe Schema for MeadowWeb

  """
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(MeadowWeb.Schema.Types.Json)

  alias Meadow.Ingest
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  import_types(__MODULE__.AccountTypes)
  import_types(__MODULE__.IngestTypes)

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
      arg(:ingest_sheet_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.delete_ingest_sheet/3)
    end

    @desc "Validate an Ingest Sheet"
    field :validate_ingest_sheet, :status_message do
      arg(:ingest_sheet_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Ingest.validate_ingest_sheet/3)
    end
  end

  subscription do
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
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end

  object :presigned_url do
    field :url, non_null(:string)
  end

  object :status_message do
    field :message, non_null(:string)
  end

  object :field do
    field :header, non_null(:string)
    field :value, non_null(:string)
  end

  object :error do
    field :field, non_null(:string)
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
