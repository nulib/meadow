defmodule Meadow.Pipeline.Actions.Common do
  @moduledoc """
  Shared functions for Meadow pipeline actions
  """
  defmacro __using__(_) do
    quote do
      use Meadow.Utils.Logging

      alias Meadow.Data.{ActionStates, FileSets}
      alias Meadow.Ingest.{Progress, Rows}

      def process(data, attrs) do
        with_log_metadata module: __MODULE__, id: data.file_set_id do
          try do
            Logger.info("Beginning #{__MODULE__} for file set: #{data.file_set_id}")

            file_set = FileSets.get_file_set(data.file_set_id)

            if file_set do
              precheck(file_set, attrs)

              with complete <-
                     ActionStates.ok?(file_set.id, __MODULE__) ||
                       ActionStates.error?(file_set.id, __MODULE__) do
                result = process(file_set, attrs, complete)
                unless complete, do: update_progress(data, attrs, result)
                result
              end
            else
              Logger.warn(
                "Marking #{__MODULE__} for #{data.file_set_id} as error because the file set was not found"
              )

              update_progress(data, attrs, {:error, "FileSet #{data.file_set_id} not found"})
              {:error, "FileSet #{data.file_set_id} not found"}
            end
          rescue
            exception ->
              Meadow.Error.report(exception, __MODULE__, __STACKTRACE__)
              reraise(exception, __STACKTRACE__)
          end
        end
      end

      defp precheck(file_set, %{overwrite: "false"} = attrs) do
        if already_complete?(file_set, attrs) do
          "Marking #{__MODULE__} for #{file_set.id} as already complete without overwriting"
          |> Logger.warn()

          ActionStates.set_state!(file_set, __MODULE__, "ok")
        end
      end

      defp precheck(_, _), do: :noop

      defp process(%{id: file_set_id}, _, true) do
        Logger.warn("Skipping #{__MODULE__} for #{file_set_id} - already complete")
        :ok
      end

      def update_progress(data, attrs, {:error, error}) do
        Progress.abort_remaining_pending_entries(attrs)
        ActionStates.abort_remaining_waiting_actions(data.file_set_id)
      end

      def update_progress(data, attrs, :skip), do: update_progress(data, attrs, :ok)

      def update_progress(data, attrs, {status, _, _}, _),
        do: update_progress(data, attrs, status)

      def update_progress(data, attrs, {status, _}, _), do: update_progress(data, attrs, status)
      def update_progress(data, attrs, {status, _}), do: update_progress(data, attrs, status)

      def update_progress(_data, %{ingest_sheet: sheet_id, ingest_sheet_row: row_num}, status) do
        Rows.get_row(sheet_id, row_num)
        |> Progress.update_entry(__MODULE__, to_string(status))
      end

      def update_progress(_, _, _), do: :noop
    end
  end
end
