defmodule Meadow.Pipeline.Action do
  @moduledoc """
  Shared functions for Meadow pipeline actions
  """
  use Meadow.Utils.Logging

  alias Broadway.Message
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Ingest.{Progress, Rows}
  alias Meadow.Pipeline.Dispatcher
  alias Meadow.Repo

  import Ecto.Query

  require Logger

  def start_link(action, opts) do
    producer_opts =
      Keyword.get(opts, :producer, [])
      |> Keyword.delete(:queue_name)
      |> Keyword.put(:queue_url, queue_url(action))

    processor_opts = Keyword.get(opts, :processors, default: [])

    Broadway.start_link(
      action,
      opts
      |> Keyword.put(:producer, module: {BroadwaySQS.Producer, producer_opts})
      |> Keyword.put(:processors, processor_opts)
      |> Keyword.put(:batchers, dispatch: [batch_size: 10])
      |> Keyword.put(:name, action)
    )
  end

  # Broadway functions

  def handle_batch(action, messages) do
    with_log_metadata action: action |> Module.split() |> List.last() do
      messages
      |> Enum.each(&dispatch_message(&1, action))

      messages
    end
  end

  def handle_message(action, %Message{data: {data, attrs}} = message) do
    with_log_metadata action: action |> Module.split() |> List.last(),
                      id: Map.get(data, :file_set_id) do
      {_status, data, attrs} = process(action, data, attrs) |> update_context(action)

      message
      |> Message.put_data(%{message: data, message_attributes: attrs})
      |> Message.put_batcher(:dispatch)
    end
  end

  def prepare_messages(action, messages) do
    messages =
      messages
      |> Enum.map(&parse_message/1)
      |> Enum.map(&action.prepare_file_set_id/1)

    file_set_ids = messages |> Enum.map(&extract_file_set_id/1) |> Enum.reject(&is_nil/1)
    file_sets = from(fs in FileSet, where: fs.id in ^file_set_ids) |> Repo.all()

    messages
    |> Enum.map(
      &Message.update_data(&1, fn data ->
        data |> replace_file_set_id(file_sets)
      end)
    )
  end

  @doc "Send processed message to its next destination (as part of the Broadway batcher)"
  def dispatch_message(
        %Message{
          data: %{message: file_set, message_attributes: %{status: "error", error: error}}
        },
        module
      ) do
    with_log_metadata module: module, id: file_set.id do
      Logger.error("Error on FileSet #{file_set.id}: #{inspect(error)}")
    end
  end

  def dispatch_message(
        %Message{data: %{message: file_set, message_attributes: %{status: "retry"} = attrs}},
        module
      ) do
    module.send_message(%{file_set_id: file_set.id}, attrs)
  end

  def dispatch_message(%Message{data: %{message: file_set, message_attributes: attrs}}, _) do
    Dispatcher.dispatch_next_action(file_set, attrs)
  end

  # Functions to support dispatching

  def sendable_message(action, data, context \\ %{}) do
    {queue_url(action),
     %{
       "Message" => data,
       "MessageAttributes" =>
         context
         |> Enum.map(fn {name, value} ->
           {name, %{"Type" => "StringValue", "Value" => value}}
         end)
         |> Enum.into(%{})
     }
     |> Jason.encode!()}
  end

  def send_message(action, data, context \\ %{}) do
    with {url, message} <- sendable_message(action, data, context) do
      url
      |> ExAws.SQS.send_message(message)
      |> ExAws.request!()
    end
  end

  # Functions to prepare incoming message for processing

  def parse_message(%Message{} = message) do
    message
    |> Message.update_data(&extract/1)
  end

  def extract(data) do
    case decode(data) do
      %{message: msg, message_attributes: attrs} ->
        {decode(msg), attrs |> attrs_to_map()}

      msg ->
        {decode(msg), %{}}
    end
  end

  def update_context({status, data, attrs}, action) do
    context_attrs = %{
      status: to_string(status),
      process: action |> to_string() |> String.split(".") |> List.last()
    }

    {
      status,
      data,
      attrs |> Map.merge(context_attrs)
    }
  end

  def extract_file_set_id(%Message{data: {%{file_set_id: id}, _}}), do: id
  def extract_file_set_id(_), do: nil

  def replace_file_set_id({%{file_set_id: file_set_id} = data, attrs}, file_sets) do
    with file_set <- file_sets |> Enum.find(&(&1.id == file_set_id)) do
      {data |> Map.put(:file_set, file_set), attrs}
    end
  end

  def replace_file_set_id(data, _), do: data

  defp decode(data) do
    case Jason.decode(data) do
      {:ok, result} -> AtomicMap.convert(result, safe: false)
      _ -> data
    end
  rescue
    ArgumentError -> data
  end

  defp attrs_to_map(attrs) do
    attrs
    |> Enum.map(fn
      %{name: name, value: value} -> {name, value}
      {name, %{value: value}} -> {name, value}
      {name, value} -> {name, value}
    end)
    |> Enum.into(%{})
  end

  # Configuration and utility functions

  @doc "Retrieve an action's configuration"
  def configuration(action) do
    Application.get_env(:meadow, Meadow.Pipeline, []) |> Keyword.get(action, [])
  end

  @doc "Retrieve an action's queue URL"
  def queue_url(action) do
    configuration(action)
    |> get_in([:producer, :queue_name])
    |> ExAws.SQS.get_queue_url()
    |> ExAws.request!()
    |> get_in([:body, :queue_url])
  end

  @doc "Process a FileSet"
  def process(action, %{file_set_id: file_set_id, file_set: nil} = data, attrs) do
    Logger.warning(
      "Marking #{action} for #{file_set_id} as error because the file set was not found"
    )

    update_progress(action, {:error, data, attrs})
    {:error, "FileSet #{file_set_id} not found"}
  end

  def process(action, %{file_set: %FileSet{} = file_set}, attrs) do
    Logger.info("Beginning #{action} for file set: #{file_set.id}")

    precheck(action, file_set, attrs)

    with complete <-
           ActionStates.ok?(file_set.id, action) ||
             ActionStates.error?(file_set.id, action) do
      result =
        case process(action, file_set, attrs, complete) do
          {:error, error} -> {:error, file_set, Map.put(attrs, :error, error)}
          status -> {status, file_set, attrs}
        end

      unless complete, do: update_progress(action, result)
      result
    end
  rescue
    exception ->
      Meadow.Error.report(exception, action, __STACKTRACE__)
      reraise(exception, __STACKTRACE__)
  end

  def process(action, data, attrs) do
    case {Map.get(data, :file_set_id, :missing), Map.get(data, :file_set, :missing)} do
      {:missing, _} ->
        with error <- "#{action} received unknown data: #{inspect({data, attrs})}" do
          Logger.warning(error)
          {:error, error}
        end

      {file_set_id, :missing} ->
        with file_set <- FileSets.get_file_set(file_set_id),
             data <- data |> Map.put(:file_set, file_set) do
          process(action, data, attrs)
        end
    end
  end

  defp process(action, %{id: file_set_id} = data, %{force: "true"} = attrs, true) do
    Logger.warning("Forcing #{action} for #{file_set_id} even though it's already complete")
    process(action, data, attrs, false)
  end

  defp process(action, %{id: file_set_id}, _, true),
    do: Logger.warning("Skipping #{action} for #{file_set_id} - already complete")

  defp process(action, data, attrs, _), do: action.process(data, attrs)

  # Check whether the action is already complete for the FileSet

  defp precheck(action, file_set, %{overwrite: "false"} = attrs) do
    if action.already_complete?(file_set, attrs) do
      "Marking #{action} for #{file_set.id} as already complete without overwriting"
      |> Logger.warning()

      ActionStates.set_state!(file_set, action, "ok")
    end
  end

  defp precheck(_, _, _), do: :noop

  @doc "Update ingest sheet progress based on the outcome of the action"
  def update_progress(action, {status, data, attrs}),
    do: update_progress(action, status, data, attrs)

  def update_progress(_, :error, %{file_set_id: file_set_id}, attrs) do
    Progress.abort_remaining_pending_entries(attrs)
    ActionStates.abort_remaining_waiting_actions(file_set_id)
  end

  def update_progress(action, :error, %FileSet{id: file_set_id}, attrs),
    do: update_progress(action, :error, %{file_set_id: file_set_id}, attrs)

  def update_progress(action, :skip, file_set, attrs),
    do: update_progress(action, :ok, file_set, attrs)

  def update_progress(action, status, _file_set, %{
        ingest_sheet: sheet_id,
        ingest_sheet_row: row_num
      }) do
    Rows.get_row(sheet_id, row_num)
    |> Progress.update_entry(action, to_string(status))
  end

  def update_progress(_, _, _, _), do: :noop
end
