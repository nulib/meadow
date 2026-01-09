defmodule Meadow.GeoNamesCase do
  @moduledoc """
  Test case for tests that use GeoNames API.
  Sets up Req.Test stub for mocking GeoNames HTTP requests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      setup do
        Meadow.GeoNamesHttpMock.setup_geonames_stub()
        :ok
      end
    end
  end
end
