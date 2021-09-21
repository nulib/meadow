defmodule IIIF.V3.Presentation.Content do
  @moduledoc """
  IIIF Presentation API 3.0.x Content
  """

  defstruct type: nil,
            id: nil,
            format: nil,
            width: nil,
            height: nil,
            duration: nil,
            label: nil,
            language: nil,
            target: nil,
            service: []
end
