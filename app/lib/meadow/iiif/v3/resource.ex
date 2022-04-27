defprotocol Meadow.IIIF.V3.Resource do
  @moduledoc """
  A protocol for converting a struct into a 2.0 IIIF Manifest
  """

  @doc """
  returns a map of fields which will be encoded into a IIIF manifest
  """
  def encode(object)
end
