defmodule IIIF.V3.Presentation.Service do
  @moduledoc """
  IIIF Presentation API 2.1.x Service
  """

  @default_profile "http://iiif.io/api/image/2/level2.json"

  defstruct id: nil,
            profile: @default_profile,
            type: nil
end
