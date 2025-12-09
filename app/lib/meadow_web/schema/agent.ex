defmodule MeadowWeb.Schema.Agent do
  @moduledoc """
  Absinthe Schema for the MeadowAI Agent

  """
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(MeadowWeb.Schema.Types.Json)

  alias Meadow.{Data, Repo}
  alias Meadow.Data.Schemas.FileSet
  import Ecto.Query

  import_types(MeadowWeb.Schema.IngestTypes)
  import_types(MeadowWeb.Schema.Data.WorkTypes)
  import_types(MeadowWeb.Schema.Data.CollectionTypes)
  import_types(MeadowWeb.Schema.Data.ControlledTermTypes)
  import_types(MeadowWeb.Schema.Data.FileSetTypes)
  import_types(MeadowWeb.Schema.Data.FieldTypes)
  import_types(MeadowWeb.Schema.NULAuthorityTypes)
  import_types(__MODULE__.WorkQueries)

  enum :sort_order do
    value(:asc)
    value(:desc)
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

  query do
    import_fields(:collection_queries)
    import_fields(:controlled_term_queries)
    import_fields(:field_queries)
    import_fields(:nul_authority_queries)
    import_fields(:agent_work_queries)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Data, Data.datasource())
      |> Dataloader.add_source(OrderedFileSets, ordered_file_set_source())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  defp ordered_file_set_source do
    Dataloader.Ecto.new(Repo,
      query: fn
        FileSet, _ -> from(f in FileSet, order_by: f.rank)
        queryable, _ -> queryable
      end
    )
  end
end
