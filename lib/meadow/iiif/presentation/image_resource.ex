defmodule IIIF.Presentation.ImageResource do
  @moduledoc """
  IIIF Presentation API 2.1.x ImageResource
  """
  @rdf_type "dctypes:Image"

  defstruct id: nil,
            label: nil,
            type: @rdf_type,
            format: nil,
            height: nil,
            width: nil,
            service: nil
end
