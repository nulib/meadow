defmodule MeadowWeb.Schema.Data.ArchivesSpaceTypes do
  @moduledoc """
  GraphQL schema types for ArchivesSpace links and synchronization
  """

  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :archives_space_queries do
    @desc "Get the ArchivesSpace link for a work"
    field :archives_space_link, :archives_space_link do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.ArchivesSpace.link/3)
    end

    @desc "List all ArchivesSpace links currently in an error state"
    field :archives_space_error_links, list_of(:archives_space_link) do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.ArchivesSpace.error_links/3)
    end

    @desc "Search ArchivesSpace resources (finding aids) by keyword"
    field :archives_space_resource_search, :archives_space_search_result do
      arg(:query, non_null(:string))
      arg(:page, :integer)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.ArchivesSpace.search_resources/3)
    end

    @desc "List ArchivesSpace resources imported into Meadow, most recent first"
    field :archives_space_imports, list_of(:archives_space_import) do
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.ArchivesSpace.imports/3)
    end
  end

  object :archives_space_subscriptions do
    @desc """
    Delivers the AI metadata preview for an ArchivesSpace import once the
    metadata agent finishes. Subscribe with the token returned by
    `archivesSpaceStartImportPreview`. Because the agent can run far longer
    than an HTTP request survives, results are pushed here rather than
    returned synchronously.
    """
    field :archives_space_import_preview, :archives_space_import_preview do
      arg(:token, non_null(:id))

      config(fn %{token: token}, _ ->
        {:ok, topic: Meadow.ArchivesSpace.ImportPreview.topic(token)}
      end)
    end
  end

  object :archives_space_mutations do
    @desc "Link a work to an ArchivesSpace archival object"
    field :link_work_to_archives_space, :archives_space_link do
      arg(:work_id, non_null(:id))
      arg(:archives_space_uri, non_null(:string))
      arg(:ref_id, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.ArchivesSpace.link_work/3)
    end

    @desc "Remove a work's ArchivesSpace link (no records are changed in either system)"
    field :unlink_work_from_archives_space, :archives_space_link do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.ArchivesSpace.unlink_work/3)
    end

    @desc "Sync a linked work's metadata to ArchivesSpace immediately"
    field :sync_work_to_archives_space, :archives_space_link do
      arg(:work_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.ArchivesSpace.sync_work/3)
    end

    @desc """
    Import an ArchivesSpace resource (finding aid) into Meadow. Creates and
    returns the linked collection immediately; linked works for its archival
    objects are created in the background.
    """
    field :import_archives_space_resource, :collection do
      arg(:resource_uri, non_null(:string))
      arg(:ai_ingest, :boolean)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.ArchivesSpace.import_resource/3)
    end

    @desc """
    Begin generating an AI metadata preview for an ArchivesSpace resource.
    Returns immediately with a token; the agent runs in the background and the
    finished preview is delivered over the `archivesSpaceImportPreview`
    subscription keyed by that token. Nothing is imported. Restricted to
    supermanagers.
    """
    field :archives_space_start_import_preview, :archives_space_import_preview do
      arg(:resource_uri, non_null(:string))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.ArchivesSpace.start_import_preview/3)
    end
  end

  @desc "A link between a Meadow work or collection and an ArchivesSpace record"
  object :archives_space_link do
    field(:id, non_null(:id))
    field(:work_id, :id)
    field(:collection_id, :id)
    field(:archives_space_uri, non_null(:string))
    field(:ref_id, :string)
    field(:repository_id, :integer)
    field(:digital_object_uri, :string)
    field(:sync_status, non_null(:archives_space_sync_status))
    field(:sync_error, :string)
    field(:last_synced_at, :datetime)
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  @desc "An ArchivesSpace resource imported into Meadow as a collection"
  object :archives_space_import do
    field(:id, non_null(:id))
    field(:archives_space_uri, non_null(:string))
    field(:finding_aid_url, :string)
    field(:sync_status, non_null(:archives_space_sync_status))
    field(:work_count, :integer)
    field(:inserted_at, non_null(:datetime))
    field(:collection, :collection)
  end

  @desc "A page of ArchivesSpace resource search results"
  object :archives_space_search_result do
    field(:results, non_null(list_of(:archives_space_search_hit)))
    field(:total_hits, :integer)
  end

  @desc "An ArchivesSpace resource matching a search"
  object :archives_space_search_hit do
    field(:uri, non_null(:string))
    field(:title, :string)
    field(:identifier, :string)
    field(:import_validation, non_null(:archives_space_import_validation))
  end

  @desc "ArchivesSpace resource import validation result"
  object :archives_space_import_validation do
    field(:importable, non_null(:boolean))
    field(:blocked_reason, :string)
    field(:blocked_count, non_null(:integer))
    field(:blocked_samples, non_null(list_of(:archives_space_import_blocked_sample)))
  end

  @desc "A blocked archival object digital object link"
  object :archives_space_import_blocked_sample do
    field(:uri, non_null(:string))
    field(:title, :string)
    field(:file_uri, non_null(:string))
  end

  @desc "An AI metadata preview for a prospective ArchivesSpace import"
  object :archives_space_import_preview do
    @desc "Token identifying this preview; used to subscribe for its result"
    field(:token, non_null(:id))
    @desc "Generation state: pending while the agent runs, then complete or error"
    field(:status, non_null(:archives_space_preview_status))
    @desc "Per-work previews, one for each sampled archival object"
    field(:previews, non_null(list_of(:archives_space_preview_item)))
    @desc "Extrapolated cost (USD) of running AI metadata over the whole resource"
    field(:estimated_cost, :float)
    @desc "Number of works actually previewed"
    field(:sample_count, :integer)
    @desc "Number of archival objects in the resource (upper bound on works created)"
    field(:total_count, :integer)
    @desc "Failure reason when status is error"
    field(:error, :string)
  end

  @desc "Generation state of an ArchivesSpace import preview"
  enum :archives_space_preview_status do
    value(:pending, description: "The metadata agent is still running")
    value(:complete, description: "The preview finished successfully")
    value(:error, description: "The preview could not be generated")
  end

  @desc "AI-generated metadata preview for a single prospective work"
  object :archives_space_preview_item do
    field(:work_accession_number, :string)
    field(:title, :string)
    field(:description, :string)
    @desc "Base64-encoded JPEG thumbnail of the representative image"
    field(:thumbnail, :string)
    field(:subjects, list_of(:archives_space_preview_subject))
  end

  @desc "A subject heading suggested for an ArchivesSpace import preview"
  object :archives_space_preview_subject do
    field(:id, :string)
    field(:label, :string)
  end

  @desc "The synchronization state of an ArchivesSpace link"
  enum :archives_space_sync_status do
    value(:linked, description: "Linked but never synced")
    value(:pending, description: "Waiting to be synced")
    value(:synced, description: "Successfully synced")
    value(:error, description: "The last sync attempt failed")
  end
end
