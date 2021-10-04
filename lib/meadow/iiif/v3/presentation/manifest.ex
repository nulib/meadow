defmodule IIIF.V3.Presentation.Manifest do
  @moduledoc """
  IIIF Presentation API 2.1.x Manifest resource
  """
  @default_context "http://iiif.io/api/presentation/3/context.json"

  @rdf_type "Manifest"

  defstruct id: nil,
            context: @default_context,
            type: @rdf_type,
            items: [],
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
            requiredStatement: nil,
            rights: nil,
            service: nil,
            seeAlso: nil,
            summary: nil,
            rendering: nil
end
