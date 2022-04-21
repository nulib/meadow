defmodule EDTF.Humanize do
  @moduledoc """
  Convert EDTF dates to human readable form
  """

  alias EDTF.Humanize

  def humanize({:ok, value}), do: humanize(value)
  def humanize({:error, _} = arg), do: arg

  def humanize(nil), do: "Unknown"

  def humanize([%{type: _} | [%{type: _}]] = values),
    do: humanize(%{type: "Interval", values: values})

  def humanize(%{type: "Interval", values: values}) do
    case values do
      [value | [%{type: "Infinity"}]] -> "from #{humanize(value)}"
      [%{type: "Infinity"} | [value]] -> "before #{humanize(value)}"
      _ -> values |> Enum.map_join(" to ", &humanize/1)
    end
  end

  def humanize(%{type: "Date"} = input), do: Humanize.Date.humanize(input)
  def humanize(%{type: "Season"} = input), do: Humanize.Date.humanize(input)
  def humanize(%{type: "Year"} = input), do: Humanize.Date.humanize(input)
  def humanize(%{type: "Decade"} = input), do: Humanize.Date.humanize(input)
  def humanize(%{type: "Century"} = input), do: Humanize.Date.humanize(input)
  def humanize(%{type: "List"} = input), do: Humanize.List.humanize(input)
  def humanize(%{type: "Set"} = input), do: Humanize.List.humanize(input)
  def humanize(%{type: "Continuation"} = input), do: Humanize.List.humanize(input)

  def humanize(input) when is_map(input) and not is_map_key(input, :type),
    do: input |> Map.put(:type, "Date") |> humanize()
end
