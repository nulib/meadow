defmodule IIIF.V2.Presentation.Sequence do
  @moduledoc """
  IIIF Presentation API 2.1.x Sequence
  """
  @default_context "http://iiif.io/api/presentation/2/context.json"
  @rdf_type "sc:Sequence"
  @default_id "/sequence/normal"

  defstruct id: @default_id,
            context: @default_context,
            type: @rdf_type,
            label: nil,
            metadata: [],
            description: nil,
            thumbnail: nil,
            viewingHint: nil,
            viewingDirection: nil,
            license: nil,
            attribution: nil,
            logo: nil,
            related: nil,
            service: nil,
            seeAlso: nil,
            rendering: nil,
            within: nil,
            canvases: [],
            startCanvas: nil
end
