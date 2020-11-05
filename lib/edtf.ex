defmodule EDTF do
  @moduledoc """
  EDTF Parsing GenServer
  """

  use GenServer

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
  def parse(value), do: GenServer.call(__MODULE__, {:parse, value})

  @doc """
  Validate an EDTF date string

  Example:
    iex> validate("1999-06-10")
    {:ok, "1999-06-10"}

    iex> validate("bad date!")
    {:error, "Invalid EDTF input: bad date!"}
  """
  def validate(value), do: GenServer.call(__MODULE__, {:validate, value})

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
    {:ok, Port.open({:spawn, Meadow.Config.edtf()}, [:binary, :exit_status])}
  end

  def handle_call({command, data}, _from, port) do
    send(port, {self(), {:command, Jason.encode!(%{cmd: command, value: data})}})
    receive_response(port)
  end

  defp receive_response(port) do
    receive do
      # :parse responses
      {^port, {:data, "[ok] " <> response}} ->
        {:reply, {:ok, Jason.decode!(response, keys: :atoms)}, port}

      {^port, {:data, "[error] " <> message}} ->
        {:reply, {:error, String.trim(message)}, port}

      # :validate responses
      {^port, {:data, "[true] " <> response}} ->
        {:reply, {:ok, String.trim(response)}, port}

      {^port, {:data, "[false] " <> message}} ->
        {:reply, {:error, String.trim(message)}, port}

      # handle process termination
      # coveralls-ignore-start
      {^port, {:exit_status, status}} ->
        Logger.error("exit_status: #{status}")
        {:stop, "port exited with status: #{status}"}
        # coveralls-ignore-stop
    after
      # coveralls-ignore-start
      @timeout ->
        Logger.error("No response after #{@timeout}ms")
        {:reply, {:error, "EDTF Parse Timeout"}, port}
        # coveralls-ignore-stop
    end
  end
end
