defmodule IIIF.V3.Presentation.AnnotationPage do
  @moduledoc """
  IIIF Presentation API 3.0.x Annotation Page
  """
  @rdf_type "AnnotationPage"

  defstruct id: nil,
            type: @rdf_type,
            items: [],
            target: nil
end
