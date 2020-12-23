defmodule Meadow.Data.CSV.Utils do
  @moduledoc """
  Common utilities to assist with CSV metadata export and import
  """

  @delimiter "|"
  @escape "\\"
  @escaped_delimiter [@escape, @delimiter] |> IO.iodata_to_binary()
  @split_regex ["\\s*(?<!\\", @escape, ")\\", @delimiter, "\\s*"]
               |> IO.iodata_to_binary()
               |> Regex.compile!()

  def combine_multivalued_field(values) do
    values
    |> Enum.map(fn str -> String.replace(str, @delimiter, @escaped_delimiter) end)
    |> Enum.join(" #{@delimiter} ")
  end

  def split_multivalued_field(combined) do
    combined
    |> String.split(@split_regex)
    |> Enum.map(fn str -> String.replace(str, @escaped_delimiter, @delimiter) end)
  end
end
