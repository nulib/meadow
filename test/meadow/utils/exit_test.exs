defmodule Meadow.Ingest.ExifTest do
  use ExUnit.Case

  alias Meadow.Utils.Exif

  setup do
    {:ok,
     %{
       "BitsPerSample" => %{"0" => 8, "1" => 8, "2" => 8},
       "Compression" => 1,
       "ExtraSamples" => 0,
       "FillOrder" => 1,
       "GrayResponseUnit" => 1,
       "PhotometricInterpretation" => 2,
       "PlanarConfiguration" => 1,
       "ResolutionUnit" => 2
     }}
  end

  test "translates BitsPerSample", context do
    assert(Exif.bits_per_sample(context["BitsPerSample"]) == "8, 8, 8")
  end

  test "translates Compression", context do
    assert(Exif.compression(context["Compression"]) == "Uncompressed")
  end

  test "translates ExtraSamples", context do
    assert(Exif.extra_samples(context["ExtraSamples"]) == "Unspecified")
  end

  test "translates FillOrder", context do
    assert(Exif.fill_order(context["FillOrder"]) == "Normal")
  end

  test "translates GrayResponseUnit", context do
    assert(Exif.gray_response_unit(context["GrayResponseUnit"]) == "0.1")
  end

  test "translates PhotometricInterpretation", context do
    assert(Exif.photometric_interpretation(context["PhotometricInterpretation"]) == "RGB")
  end

  test "translates PlanarConfiguration", context do
    assert(Exif.planar_configuration(context["PlanarConfiguration"]) == "Chunky")
  end

  test "translates ResolutionUnit", context do
    assert(Exif.resolution_unit(context["ResolutionUnit"]) == "inches")
  end
end
