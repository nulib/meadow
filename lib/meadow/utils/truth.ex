defmodule Meadow.Utils.Truth do
  @moduledoc """
  Module to assist with interpretation of spreadsheet/csv booleans
  """

  @false_values ["false", "f", "no", "n", "0", false, 0]
  @true_values ["true", "t", "yes", "y", "1", "-1", true, 1, -1]

  @doc """
  Returns true if the value is one of the known truthy boolean values

  Examples:

    iex> true?("true")
    true

    iex> true?("t")
    true

    iex> true?("yes")
    true

    iex> true?("y")
    true

    iex> true?("1")
    true

    iex> true?("-1")
    true

    iex> true?(true)
    true

    iex> true?(1)
    true

    iex> true?(-1)
    true

    iex> true?(:true)
    true

    iex> true?(false)
    false

    iex> true?("x")
    false
  """
  def true?(value), do: @true_values |> Enum.member?(normalize(value))

  @doc """
  Returns true if the value is one of the known truthy boolean values

  Examples:

    iex> false?("false")
    true

    iex> false?("f")
    true

    iex> false?("no")
    true

    iex> false?("n")
    true

    iex> false?("0")
    true

    iex> false?(false)
    true

    iex> false?(0)
    true

    iex> false?(:false)
    true

    iex> false?(true)
    false

    iex> false?("x")
    false
  """
  def false?(value), do: @false_values |> Enum.member?(normalize(value))

  @doc """
  Converts the given value to a boolean based on the known truthy values

  Examples:

    iex> to_bool("true")
    true

    iex> to_bool("false")
    false

    iex> to_bool("1")
    true

    iex> to_bool("0")
    false

    iex> to_bool("x")
    :unknown
  """
  def to_bool(value) do
    cond do
      true?(value) -> true
      false?(value) -> false
      true -> :unknown
    end
  end

  defp normalize(value) when is_binary(value), do: String.downcase(value)
  defp normalize(value), do: value
end
