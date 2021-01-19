defmodule EDTF do
  @moduledoc """
  EDTF Parsing GenServer
  """

  alias Meadow.Config
  alias Meadow.Utils.Lambda

  import Meadow.Utils.Atoms

  require Logger

  @timeout 1000

  @doc """
  Parse an EDTF date string

  Example:
    iex> parse("1999-06-10")
    {:ok, %{level: 0, type: "Date", values: [1999, 5, 10]}}

    iex> parse("bad date!")
    {:error, "Invalid EDTF input: bad date!"}
  """
  def parse(value) do
    case Lambda.invoke(Config.lambda_config(:edtf), %{function: :parse, value: value}, @timeout) do
      {:ok, result} -> {:ok, atomize(result)}
      other -> other
    end
  end

  @doc """
  Validate an EDTF date string

  Example:
    iex> validate("1999-06-10")
    {:ok, "1999-06-10"}

    iex> validate("bad date!")
    {:error, "Invalid EDTF input: bad date!"}
  """
  def validate(value),
    do: Lambda.invoke(Config.lambda_config(:edtf), %{function: :validate, value: value}, @timeout)

  @doc """
  Humanize an EDTF date string

  Example:
    iex> humanize("1999-06-10")
    "June 10, 1999"

    iex> humanize("bad date!")
    {:error, "Invalid EDTF input: bad date!"}
  """
  def humanize(value) do
    case value |> parse() |> EDTF.Humanize.humanize() do
      :original -> value
      other -> other
    end
  end
end
