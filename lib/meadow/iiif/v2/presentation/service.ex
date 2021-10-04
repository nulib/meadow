defmodule IIIF.V2.Presentation.Service do
  @moduledoc """
  IIIF Presentation API 2.1.x Service
  """
  @default_context "http://iiif.io/api/image/2/context.json"
  @default_profile "http://iiif.io/api/image/2/level2.json"

  defstruct context: @default_context,
            id: nil,
            profile: @default_profile
end
