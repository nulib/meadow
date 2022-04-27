defmodule EDTF do
  @moduledoc """
  EDTF Parsing GenServer
  """

  use GenServer

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
    case GenServer.call(__MODULE__, {:parse, value}) do
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
    do: GenServer.call(__MODULE__, {:validate, value})

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

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Logger.info("Starting EDTF Parser")

    case script_config() |> Lambda.init() do
      {_, port} -> {:ok, port}
      other -> other
    end
  end

  def handle_call({command, data}, _from, port) do
    {:reply, script_config() |> Lambda.invoke(%{function: command, value: data}, @timeout), port}
  end

  defp script_config, do: {:local, {Config.priv_path("nodejs/edtf/index.js"), "handler"}}
end
