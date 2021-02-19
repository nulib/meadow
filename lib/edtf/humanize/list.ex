defmodule EDTF.Humanize.List do
  @moduledoc """
  Humanize EDTF Set and List types
  """

  alias EDTF.Humanize

  @units [nil, "year", "month", "date"]

  def humanize(%{type: "Set"} = input) do
    input
    |> humanize_list_or_set_values()
    |> make_list("or")
  end

  def humanize(%{type: "List"} = input) do
    input
    |> humanize_list_or_set_values()
    |> make_list("and")
  end

  def humanize(%{type: "Continuation", subtype: "Set", position: :earlier, value: value}) do
    with {human, time_unit} <- humanize_with_unit(value) do
      "some #{time_unit} before #{human}"
    end
  end

  def humanize(%{type: "Continuation", subtype: "Set", position: :later, value: value}) do
    with {human, time_unit} <- humanize_with_unit(value) do
      "some #{time_unit} after #{human}"
    end
  end

  def humanize(%{type: "Continuation", subtype: "List", position: :earlier, value: value}) do
    with {human, time_unit} <- humanize_with_unit(value) do
      "all #{Inflex.pluralize(time_unit)} before #{human}"
    end
  end

  def humanize(%{type: "Continuation", subtype: "List", position: :later, value: value}) do
    with {human, time_unit} <- humanize_with_unit(value) do
      "all #{Inflex.pluralize(time_unit)} after #{human}"
    end
  end

  defp continuation(type, position, value),
    do: %{type: "Continuation", subtype: type, position: position, value: value}

  defp humanize_list_or_set_values(%{type: type, values: values} = input) do
    first_value = List.first(values)
    last_value = List.last(values)

    case input do
      %{earlier: true, later: true} ->
        [continuation(type, :earlier, first_value) | values] ++
          [continuation(type, :later, last_value)]

      %{earlier: true} ->
        [continuation(type, :earlier, first_value) | values]

      %{later: true} ->
        values ++ [continuation(type, :later, last_value)]

      _ ->
        values
    end
    |> Enum.map(&Humanize.humanize/1)
  end

  defp humanize_with_unit(value) do
    {Humanize.humanize(value), precision(value)}
  end

  defp precision(value), do: Enum.at(@units, length(value.values))

  defp make_list([item], _trailing_join), do: item

  defp make_list(items, trailing_join) when length(items) == 2 do
    Enum.join(items, " #{trailing_join} ")
  end

  defp make_list(items, trailing_join) do
    [Enum.slice(items, 0..-2) |> Enum.join(", "), List.last(items)]
    |> Enum.join(", #{trailing_join} ")
  end
end
