defmodule Meadow.Utils.Exif do
  @moduledoc """
  Functions for working with EXIF metadata
  """

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

  def bits_per_sample(bits_per_sample) when is_map(bits_per_sample) do
    Enum.map_join(bits_per_sample, ", ", fn {_key, value} -> value end)
  end

  def bits_per_sample(_), do: nil

  def compression(value) do
    Map.get(@compression_mapping, value)
  end

  def extra_samples(value) do
    case value do
      0 -> "Unspecified"
      1 -> "Associated Alpha"
      2 -> "Unassociated Alpha"
      _ -> nil
    end
  end

  def fill_order(value) do
    case value do
      1 -> "Normal"
      2 -> "Reversed"
      _ -> nil
    end
  end

  def gray_response_unit(value) do
    case value do
      1 -> "0.1"
      2 -> "0.001"
      3 -> "0.0001"
      4 -> "1e-05"
      5 -> "1e-06"
      _ -> nil
    end
  end

  def photometric_interpretation(value) do
    Map.get(@photometric_interpretation, value)
  end

  def planar_configuration(value) do
    case value do
      1 -> "Chunky"
      2 -> "Planar"
      _ -> nil
    end
  end

  def resolution_unit(value) do
    case value do
      1 -> "None"
      2 -> "inches"
      3 -> "cm"
      _ -> nil
    end
  end
end
