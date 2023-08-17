defmodule Meadow.Utils.Exif do
  @moduledoc """
  Functions for working with EXIF metadata
  """

  alias Meadow.Utils.Atoms

  require Logger

  @compression_mapping %{
    1 => "Uncompressed",
    2 => "CCITT 1D",
    3 => "T4/Group 3 Fax",
    4 => "T6/Group 4 Fax",
    5 => "LZW",
    6 => "JPEG (old-style)",
    7 => "JPEG",
    8 => "Adobe Deflate",
    9 => "JBIG B&W",
    10 => "JBIG Color",
    99 => "JPEG",
    262 => "Kodak 262",
    32_766 => "Next",
    32_767 => "Sony ARW Compressed",
    32_769 => "Packed RAW",
    32_770 => "Samsung SRW Compressed",
    32_771 => "CCIRLEW",
    32_772 => "Samsung SRW Compressed 2",
    32_773 => "PackBits",
    32_809 => "Thunderscan",
    32_867 => "Kodak KDC Compressed",
    32_895 => "IT8CTPAD",
    32_896 => "IT8LW",
    32_897 => "IT8MP",
    32_898 => "IT8BL",
    32_908 => "PixarFilm",
    32_909 => "PixarLog",
    32_946 => "Deflate",
    32_947 => "DCS",
    33_003 => "Aperio JPEG 2000 YCbCr",
    33_005 => "Aperio JPEG 2000 RGB",
    34_661 => "JBIG",
    34_676 => "SGILog",
    34_677 => "SGILog24",
    34_712 => "JPEG 2000",
    34_713 => "Nikon NEF Compressed",
    34_715 => "JBIG2 TIFF FX",
    34_718 => "Microsoft Document Imaging (MDI) Binary Level Codec",
    34_719 => "Microsoft Document Imaging (MDI) Progressive Transform Codec",
    34_720 => "Microsoft Document Imaging (MDI) Vector",
    34_887 => "ESRI Lerc",
    34_892 => "Lossy JPEG",
    34_925 => "LZMA2",
    34_926 => "Zstd",
    34_927 => "WebP",
    34_933 => "PNG",
    34_934 => "JPEG XR",
    65_000 => "Kodak DCR Compressed",
    65_535 => "Pentax PEF Compressed"
  }

  @photometric_interpretation %{
    0 => "WhiteIsZero",
    1 => "BlackIsZero",
    2 => "RGB",
    3 => "RGB Palette",
    4 => "Transparency Mask",
    5 => "CMYK",
    6 => "YCbCr",
    8 => "CIELab",
    9 => "ICCLab",
    10 => "ITULab",
    32_803 => "Color Filter Array",
    32_844 => "Pixar LogL",
    32_845 => "Pixar LogLuv",
    32_892 => "Sequential Color Filter",
    34_892 => "Linear Raw",
    51_177 => "Depth Map"
  }

  @subfile_type %{
    0x0 => "Full-resolution image",
    0x1 => "Reduced-resolution image",
    0x2 => "Single page of multi-page image",
    0x3 => "Single page of multi-page reduced-resolution image",
    0x4 => "Transparency mask",
    0x5 => "Transparency mask of reduced-resolution image",
    0x6 => "Transparency mask of multi-page image",
    0x7 => "Transparency mask of reduced-resolution multi-page image",
    0x8 => "Depth map",
    0x9 => "Depth map of reduced-resolution image",
    0x10 => "Enhanced image data",
    0x10001 => "Alternate reduced-resolution image",
    0xFFFFFFFF => "invalid"
  }

  @indexable_fields ~w(BitsPerSample Compression ExtraSamples FillOrder GrayResponseUnit ImageHeight
    ImageWidth Make Model PhotometricInterpretation PlanarConfiguration ResolutionUnit
    XResolution YResolution)

  @doc """
  Transform EXIF metadata with human readable values

  Examples:

    iex> transform(nil)
    nil

    iex> %{
    ...>    "BitsPerSample" => %{"0" => 8, "1" => 8, "2" => 8},
    ...>    "Compression" => 7,
    ...>    "ExtraSamples" => 2,
    ...>    "FillOrder" => 1,
    ...>    "GrayResponseUnit" => 3,
    ...>    "ImageHeight" => 9026,
    ...>    "ImageWidth" => 25183,
    ...>    "Orientation" => "Horizontal (normal)",
    ...>    "PhotometricInterpretation" => 6,
    ...>    "PlanarConfiguration" => 1,
    ...>    "ResolutionUnit" => 2,
    ...>    "SamplesPerPixel" => 3,
    ...>    "Software" => "Adobe Photoshop CC (Macintosh)",
    ...>    "SubfileType" => 0,
    ...>    "XResolution" => 600,
    ...>    "YResolution" => 600
    ...>  } |> transform()
    %{
      "bitsPerSample" => "8, 8, 8",
      "compression" => "JPEG",
      "extraSamples" => "Unassociated Alpha",
      "fillOrder" => "Normal",
      "grayResponseUnit" => "0.0001",
      "imageHeight" => 9026,
      "imageWidth" => 25183,
      "orientation" => "Horizontal (normal)",
      "photometricInterpretation" => "YCbCr",
      "planarConfiguration" => "Chunky",
      "resolutionUnit" => "inches",
      "samplesPerPixel" => 3,
      "software" => "Adobe Photoshop CC (Macintosh)",
      "subfileType" => "Full-resolution image",
      "xResolution" => 600,
      "yResolution" => 600
    }

    iex> %{
    ...>   "ExtraSamples" => %{"0" => 0, "1" => 2},
    ...>   "XResolution" => 1.2932398880691411,
    ...>   "YResolution" => 1.1068155680259393
    ...> } |> transform()
    %{
      "extraSamples" => "Unspecified, Unassociated Alpha",
      "xResolution" => 1.2932398880691411,
      "yResolution" => 1.1068155680259393
    }
  """
  def transform(nil), do: nil

  def transform(metadata) do
    metadata
    |> Enum.map(fn {key, value} -> {Inflex.camelize(key, :lower), transform_value(key, value)} end)
    |> Enum.into(%{})
  end

  @doc """
  Produce indexable EXIF metadata

  Examples:

    iex> index(nil)
    nil

    iex> %{
    ...>    "BitsPerSample" => %{"0" => 8, "1" => 8, "2" => 8},
    ...>    "Compression" => 7,
    ...>    "ExtraSamples" => 2,
    ...>    "FillOrder" => 1,
    ...>    "GrayResponseUnit" => 3,
    ...>    "ImageHeight" => 9026,
    ...>    "ImageWidth" => 25183,
    ...>    "Orientation" => "Horizontal (normal)",
    ...>    "PhotometricInterpretation" => 6,
    ...>    "PlanarConfiguration" => 1,
    ...>    "ResolutionUnit" => 2,
    ...>    "SamplesPerPixel" => 3,
    ...>    "Software" => "Adobe Photoshop CC (Macintosh)",
    ...>    "SubfileType" => 0,
    ...>    "XResolution" => 600,
    ...>    "YResolution" => 600
    ...>  } |> index()
    %{
       bitsPerSample: "8, 8, 8",
       compression: "JPEG",
       extraSamples: "Unassociated Alpha",
       fillOrder: "Normal",
       grayResponseUnit: "0.0001",
       imageHeight: 9026,
       imageWidth: 25183,
       photometricInterpretation: "YCbCr",
       planarConfiguration: "Chunky",
       resolutionUnit: "inches",
       xResolution: 600,
       yResolution: 600
    }

    iex> %{
    ...>    "BitsPerSample" => %{"0" => 8, "1" => 8, "2" => 8},
    ...>    "Compression" => 7,
    ...>    "Software" => "Adobe Photoshop CC (Macintosh)",
    ...>    "XResolution" => 600,
    ...>    "YResolution" => 600
    ...>  } |> index([:bits_per_sample, "software", "XResolution", :yResolution])
    %{
       bitsPerSample: "8, 8, 8",
       software: "Adobe Photoshop CC (Macintosh)",
       xResolution: 600,
       yResolution: 600
    }

    iex> %{
    ...>   "ExtraSamples" => %{"0" => 0, "1" => 2},
    ...>   "XResolution" => 1.2932398880691411,
    ...>   "YResolution" => 1.1068155680259393
    ...> } |> index()
    %{
      extraSamples: "Unspecified, Unassociated Alpha",
      xResolution: 1.2932398880691411,
      yResolution: 1.1068155680259393
    }
  """
  def index(metadata, fields \\ @indexable_fields)

  def index(nil, _), do: nil

  def index(metadata, fields) do
    with fields <- fields |> Enum.map(&Inflex.camelize/1) do
      metadata
      |> Map.take(fields)
      |> transform()
      |> Atoms.atomize()
    end
  end

  defp transform_value("BitsPerSample", value) when is_map(value) do
    value
    |> Map.values()
    |> Enum.join(", ")
  end

  defp transform_value("BitsPerSample", _), do: nil

  defp transform_value("Compression", value) do
    Map.get(@compression_mapping, value, passthrough(value))
  end

  defp transform_value("ExtraSamples", value) when is_map(value) do
    value
    |> Map.values()
    |> Enum.map_join(", ", &transform_value("ExtraSamples", &1))
  end

  defp transform_value("ExtraSamples", value) when is_integer(value) do
    case value do
      0 -> "Unspecified"
      1 -> "Associated Alpha"
      2 -> "Unassociated Alpha"
      other -> passthrough(other)
    end
  end

  defp transform_value("ExtraSamples", value), do: passthrough(value)

  defp transform_value("FillOrder", value) do
    case value do
      1 -> "Normal"
      2 -> "Reversed"
      other -> passthrough(other)
    end
  end

  defp transform_value("GrayResponseUnit", value) do
    case value do
      1 -> "0.1"
      2 -> "0.001"
      3 -> "0.0001"
      4 -> "1e-05"
      5 -> "1e-06"
      other -> passthrough(other)
    end
  end

  defp transform_value("PhotometricInterpretation", value) do
    Map.get(@photometric_interpretation, value, passthrough(value))
  end

  defp transform_value("PlanarConfiguration", value) do
    case value do
      1 -> "Chunky"
      2 -> "Planar"
      other -> passthrough(other)
    end
  end

  defp transform_value("ResolutionUnit", value) do
    case value do
      1 -> "None"
      2 -> "inches"
      3 -> "cm"
      other -> passthrough(other)
    end
  end

  defp transform_value("SubfileType", value) do
    Map.get(@subfile_type, value, passthrough(value))
  end

  defp transform_value(_, value), do: passthrough(value)

  defp passthrough(nil), do: nil
  defp passthrough(value) when is_binary(value), do: value
  defp passthrough(value) when is_integer(value), do: value
  defp passthrough(value) when is_float(value), do: value
  defp passthrough(value) when is_boolean(value), do: to_string(value)

  defp passthrough(value) when is_list(value) do
    value
    |> Enum.map(&passthrough/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp passthrough(value) do
    case String.Chars.impl_for(value) do
      nil ->
        Logger.warning("Cannot transform EXIF value #{inspect(value)} into indexable metadata")
        nil

      _ ->
        to_string(value)
    end
  end
end
