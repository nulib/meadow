defmodule IIIF.V2.Presentation.Image do
  @moduledoc """
  IIIF Presentation API 2.1.x Image resource
  """
  @default_type "oa:Annotation"

  defstruct type: @default_type,
            motivation: "sc:painting",
            on: nil,
            resource: nil
end
