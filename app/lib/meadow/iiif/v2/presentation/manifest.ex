defmodule IIIF.V2.Presentation.Manifest do
  @moduledoc """
  IIIF Presentation API 2.1.x Manifest resource
  """
  @default_context "http://iiif.io/api/presentation/2/context.json"
  @rdf_type "sc:Manifest"

  defstruct id: nil,
            context: @default_context,
            type: @rdf_type,
            label: nil,
            metadata: [],
            description: nil,
            thumbnail: nil,
            viewingHint: nil,
            viewingDirection: nil,
            navDate: nil,
            license: nil,
            attribution: nil,
            logo: nil,
            related: nil,
            service: nil,
            seeAlso: nil,
            rendering: nil,
            within: nil,
            sequences: []
end
