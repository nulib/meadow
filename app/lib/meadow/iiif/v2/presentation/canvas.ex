defmodule IIIF.V2.Presentation.Canvas do
  @moduledoc """
  IIIF Presentation API 2.1.x Canvas resource
  """
  @rdf_type "sc:Canvas"
  @default_width "640"
  @default_height "480"

  defstruct id: nil,
            type: @rdf_type,
            label: nil,
            metadata: [],
            description: nil,
            thumbnail: nil,
            viewingHint: nil,
            license: nil,
            attribution: nil,
            logo: nil,
            related: nil,
            service: nil,
            seeAlso: nil,
            rendering: nil,
            within: nil,
            images: [],
            otherContent: [],
            height: @default_height,
            width: @default_width
end
