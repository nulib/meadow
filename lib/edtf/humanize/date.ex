defmodule EDTF.Humanize.Date do
  @moduledoc """
  Humanize EDTF Date, Year, Decade, Century, and Season types
  """

  @bce_suffix " BCE"
  @months ~w(January February March April May June July August September October November December)
  @seasons %{
    21 => "Spring",
    22 => "Summer",
    23 => "Autumn",
    24 => "Winter",
    25 => "Spring (Northern Hemisphere)",
    26 => "Summer (Northern Hemisphere)",
    27 => "Autumn (Northern Hemisphere)",
    28 => "Winter (Northern Hemisphere)",
    29 => "Spring (Southern Hemisphere)",
    30 => "Summer (Southern Hemisphere)",
    31 => "Autumn (Southern Hemisphere)",
    32 => "Winter (Southern Hemisphere)",
    33 => "Quarter 1",
    34 => "Quarter 2",
    35 => "Quarter 3",
    36 => "Quarter 4",
    37 => "Quadrimester 1",
    38 => "Quadrimester 2",
    39 => "Quadrimester 3",
    40 => "Semestral 1",
    41 => "Semestral 2"
  }

  def humanize(%{type: "Date", approximate: _v, values: _values} = input) do
    "circa " <> (input |> Map.delete(:approximate) |> humanize())
  end

  def humanize(%{type: "Date", unspecified: 15, values: values})
      when length(values) == 1,
      do: "Unknown"

  def humanize(%{type: "Date", unspecified: unspecified, values: values} = input)
      when unspecified in [8, 12, 14] and length(values) == 1 do
    input
    |> Map.delete(:unspecified)
    |> humanize()
    |> String.replace(~r/(\d+)/, "\\0s")
  end

  def humanize(%{type: "Date", unspecified: _unspecified, values: _values}) do
    :original
  end

  def humanize(%{type: "Date", uncertain: _v, values: _values} = input) do
    (input |> Map.delete(:uncertain) |> humanize()) <> "?"
  end

  def humanize(%{type: "Date", values: values}) do
    case values do
      [year | [month | [day]]] -> "#{Enum.at(@months, month)} #{day}, #{set_era(year)}"
      [year | [month]] -> "#{Enum.at(@months, month)} #{set_era(year)}"
      [year] -> "#{set_era(year)}"
    end
  end

  def humanize(%{type: "Season", values: [year | [season]]}) when year < 0,
    do: Map.get(@seasons, season) <> " #{-year}#{@bce_suffix}"

  def humanize(%{type: "Season", values: [year | [season]]}),
    do: Map.get(@seasons, season) <> " #{year}"

  def humanize(%{type: "Year", values: [value]}), do: set_era(value)

  def humanize(%{type: "Decade", values: [value]}) when value < 0,
    do: "#{-value * 10}s#{@bce_suffix}"

  def humanize(%{type: "Decade", values: [value]}), do: "#{value * 10}s"

  def humanize(%{type: "Century", values: [value]}) when value < 0,
    do: "#{Inflex.ordinalize(-value)} Century#{@bce_suffix}"

  def humanize(%{type: "Century", values: [value]}), do: "#{Inflex.ordinalize(value)} Century"

  defp set_era(year) do
    if year < 0, do: "#{-year}#{@bce_suffix}", else: to_string(year)
  end
end
