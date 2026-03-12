defmodule MeadowWeb.MCP.Resources.Schemas do
  @moduledoc false

  defmacro __using__(opts) do
    uri = Keyword.fetch!(opts, :uri)
    schema = Keyword.fetch!(opts, :schema)
    read_only = Keyword.get(opts, :read_only, [])

    quote do
      use Anubis.Server.Component,
        type: :resource,
        mime_type: "application/json",
        uri: unquote(uri)

      alias Anubis.MCP.Error, as: MCPError
      alias Anubis.Server.Response

      @impl true
      def read(%{"uri" => unquote(uri)}, frame) do
        content = Meadow.Utils.Ecto.Schema.unroll(unquote(schema), read_only: unquote(read_only))
        response =
          Response.resource()
          |> Response.json(content, annotations: [audience: ["assistant"]])
        {:reply, response, frame}
      end
      def read(params, frame), do: {:error, MCPError.resource(:not_found, %{uri: params["uri"]}), frame}
    end
  end
end

defmodule MeadowWeb.MCP.Resources.Schemas.Work do
  @moduledoc "JSON schema for a Work resource, including field types and structure"

  @ro_descriptive_metadata_fields  [:ark, :box_name, :box_number, :folder_name, :folder_number, :identifier,
    :legacy_identifier, :terms_of_use, :physical_description_material, :physical_description_size,
    :provenance, :publisher, :related_material, :rights_holder, :scope_and_contents, :series, :source,
    :table_of_contents, :inserted_at, :updated_at]
  @ro_fields [:id, :accession_number, :collection_id, :behavior, :visibility, :published, :inserted_at,
    :updated_at, :ingest_sheet_id, :representative_file_set_id, :work_type, :administrative_metadata,
    descriptive_metadata: @ro_descriptive_metadata_fields]

  use MeadowWeb.MCP.Resources.Schemas,
    uri: "file://schema/work.json",
    schema: Meadow.Data.Schemas.Work,
    read_only: @ro_fields
end

defmodule MeadowWeb.MCP.Resources.Schemas.FileSet do
  @moduledoc "JSON schema for a FileSet resource, including field types and structure"

  @ro_fields [:id, :inserted_at, :updated_at, :work_id, :extracted_metadata, :derivatives,
    core_metadata: [:id, :original_filename]]

  use MeadowWeb.MCP.Resources.Schemas,
    uri: "file://schema/file_set.json",
    schema: Meadow.Data.Schemas.FileSet,
    read_only: @ro_fields
end

defmodule MeadowWeb.MCP.Resources.Schemas.Collection do
  @moduledoc "JSON schema for a Collection resource, including field types and structure"

  @ro_fields [:id, :representative_work_id, :featured, :published, :visibility, :inserted_at, :updated_at]

  use MeadowWeb.MCP.Resources.Schemas,
    uri: "file://schema/collection.json",
    schema: Meadow.Data.Schemas.Collection,
    read_only: @ro_fields
end
