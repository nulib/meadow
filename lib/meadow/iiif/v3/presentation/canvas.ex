defmodule IIIF.V3.Presentation.Canvas do
  @moduledoc """
  IIIF Presentation API 2.1.x Canvas resource
  """
  @rdf_type "Canvas"
  @default_width "640"
  @default_height "480"

  defstruct id: nil,
            type: @rdf_type,
            label: nil,
            metadata: [],
            items: [],
            duration: nil,
            height: @default_height,
            width: @default_width,
            thumbnail: nil
end
