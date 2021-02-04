defmodule Meadow.Pipeline.Actions.Common do
  @moduledoc """
  Shared functions for Meadow pipeline actions
  """
  defmacro __using__(_) do
    quote do
      alias Meadow.Data.ActionStates
      alias Meadow.Ingest.{Progress, Rows}

      def process(data, attrs) do
        with complete <- ActionStates.ok?(data.file_set_id, __MODULE__) do
          result = process(data, attrs, complete)
          unless complete, do: update_progress(data, attrs, result)
          result
        end
      end

      defp process(%{file_set_id: file_set_id}, _, true) do
        Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
        :ok
      end

      def update_progress(data, attrs, {:error, error}) do
        Progress.abort_remaining_pending_entries(attrs)
        ActionStates.abort_remaining_waiting_actions(data.file_set_id)
      end

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
