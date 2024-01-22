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
    |> Enum.map_join(" #{@delimiter} ", &escape_delimiters/1)
  end

  def split_multivalued_field(combined) do
    combined
    |> String.split(@split_regex)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&unescape_delimiters/1)
    |> Enum.reject(&empty?/1)
  end

  defp empty?(string), do: is_nil(string) || string == ""
  defp escape_delimiters(string), do: String.replace(string, @delimiter, @escaped_delimiter)
  defp unescape_delimiters(string), do: String.replace(string, @escaped_delimiter, @delimiter)
end
