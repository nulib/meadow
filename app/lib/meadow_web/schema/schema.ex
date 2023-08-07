defmodule MeadowWeb.Schema do
  @moduledoc """
  Absinthe Schema for MeadowWeb

  """
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(MeadowWeb.Schema.Types.Json)

  alias Meadow.{Data, Ingest, Repo}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Ingest.Schemas.Sheet
  import Ecto.Query

  import_types(__MODULE__.AccountTypes)
  import_types(__MODULE__.Data.WorkTypes)
  import_types(__MODULE__.Data.BatchTypes)
  import_types(__MODULE__.IngestTypes)
  import_types(__MODULE__.Data.CollectionTypes)
  import_types(__MODULE__.Data.ControlledTermTypes)
  import_types(__MODULE__.Data.FileSetTypes)
  import_types(__MODULE__.Data.FieldTypes)
  import_types(__MODULE__.Data.PreservationCheckTypes)
  import_types(__MODULE__.Data.SharedLinkTypes)
  import_types(__MODULE__.HelperTypes)
  import_types(__MODULE__.Data.CSVMetadataUpdateTypes)
  import_types(__MODULE__.NULAuthorityTypes)

  query do
    import_fields(:account_queries)
    import_fields(:batch_queries)
    import_fields(:collection_queries)
    import_fields(:controlled_term_queries)
    import_fields(:field_queries)
    import_fields(:file_set_queries)
    import_fields(:helper_queries)
    import_fields(:ingest_queries)
    import_fields(:csv_metadata_update_queries)
    import_fields(:nul_authority_queries)
    import_fields(:preservation_check_queries)
    import_fields(:work_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:batch_mutations)
    import_fields(:collection_mutations)
    import_fields(:file_set_mutations)
    import_fields(:ingest_mutations)
    import_fields(:csv_metadata_update_mutations)
    import_fields(:nul_authority_mutations)
    import_fields(:shared_link_mutations)
    import_fields(:work_mutations)
  end

  subscription do
    import_fields(:ingest_subscriptions)
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end

  object :api_token do
    field :token, non_null(:string)
    field :expires, non_null(:datetime)
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

  object :errors do
    field :field, non_null(:string)
    field :messages, list_of(:string)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Ingest, Ingest.datasource())
      |> Dataloader.add_source(OrderedIngestSheets, ordered_ingest_sheet_source())
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

  defp ordered_ingest_sheet_source do
    Dataloader.Ecto.new(Repo,
      query: fn
        Sheet, _ -> from(s in Sheet, order_by: [desc: s.updated_at])
        queryable, _ -> queryable
      end
    )
  end
end
