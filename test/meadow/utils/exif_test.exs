defmodule Meadow.Ingest.ExifTest do
  use ExUnit.Case
  alias Meadow.Utils.Exif
  import ExUnit.CaptureLog
  import ExUnit.DocTest

  doctest(Exif, import: true)

  test "passthrough/1" do
    log =
      capture_log(fn ->
        assert %{
                 "BitsPerSample" => :atom,
                 "Compression" => 27,
                 "ExtraSamples" => "string",
                 "FillOrder" => true,
                 "GrayResponseUnit" => nil,
                 "PhotometricInterpretation" => %{"unknown" => "map"},
                 "PlanarConfiguration" => [27, "string", true]
               }
               |> Exif.index() == %{
                 bitsPerSample: nil,
                 compression: 27,
                 extraSamples: "string",
                 fillOrder: "true",
                 grayResponseUnit: nil,
                 photometricInterpretation: nil,
                 planarConfiguration: "27, string, true"
               }
      end)

    assert log
           |> String.contains?(
             ~s'Cannot transform EXIF value %{"unknown" => "map"} into indexable metadata'
           )
  end
end
