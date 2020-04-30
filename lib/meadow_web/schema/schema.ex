defmodule MeadowWeb.Schema do
  @moduledoc """
  Absinthe Schema for MeadowWeb

  """
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(MeadowWeb.Schema.Types.Json)

  alias Meadow.Data
  alias Meadow.Ingest

  import_types(__MODULE__.AccountTypes)
  import_types(__MODULE__.IngestTypes)
  import_types(__MODULE__.Data.CollectionTypes)
  import_types(__MODULE__.Data.ControlledVocabularyTypes)
  import_types(__MODULE__.Data.WorkTypes)
  import_types(__MODULE__.Data.FileSetTypes)
  import_types(__MODULE__.HelperTypes)

  query do
    import_fields(:account_queries)
    import_fields(:collection_queries)
    import_fields(:ingest_queries)
    import_fields(:work_queries)
    import_fields(:file_set_queries)
    import_fields(:helper_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:ingest_mutations)
    import_fields(:collection_mutations)
    import_fields(:work_mutations)
    import_fields(:file_set_mutations)
  end

  subscription do
    import_fields(:ingest_subscriptions)
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end

  object :url do
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
      |> Dataloader.add_source(Data, Data.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
