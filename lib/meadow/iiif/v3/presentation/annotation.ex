defmodule IIIF.V3.Presentation.Annotation do
  @moduledoc """
  IIIF Presentation API 3.0.x Annotation
  """
  @rdf_type "Annotation"

  defstruct id: nil,
            type: @rdf_type,
            motivation: "painting",
            body: nil,
            target: nil
end
