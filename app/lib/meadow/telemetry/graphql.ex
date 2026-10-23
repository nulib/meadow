defmodule Meadow.Telemetry.GraphQL do
  @moduledoc """
  Emit additional telemetry for Absinthe GraphQL operations.

  Re-emits `[:absinthe, :execute, :operation, :stop]` as
  `[:meadow, :graphql, :operation, :time]` with the operation type and the top-level field
  names attached. Consumed by Live Dashboard only -- these are deliberately not routed to
  CloudWatch.

  Note that the operation duration is emitted once per top-level field, so an operation
  selecting several fields contributes several full-duration samples. Percentiles read
  across the whole metric are still meaningful; counts and sums are inflated by the
  average number of top-level fields per operation.
  """

  require Logger

  def handle_absinthe_timing_event(
        [:absinthe, :execute, :operation, :stop],
        measurements,
        metadata,
        _config
      ) do
    find_operations(metadata.blueprint)
    |> Enum.each(fn %{operation_type: operation_type, fields: fields} ->
      Enum.each(fields, fn field ->
        :telemetry.execute([:meadow, :graphql, :operation, :time], measurements, %{
          type: operation_type,
          field: field
        })
      end)
    end)
  rescue
    exception ->
      Logger.warning("Unable to re-emit Absinthe timing: #{Exception.message(exception)}")
      :ok
  end

  def find_operations(input) do
    walk(input)
    |> parse_output()
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
  end

  defp walk([]), do: []

  defp walk(operations) when is_list(operations) do
    Enum.map(operations, fn op -> walk(op) end)
  end

  defp walk(%Absinthe.Blueprint{} = blueprint) do
    walk(blueprint.operations)
  end

  defp walk(%Absinthe.Blueprint.Document.Operation{} = operation) do
    {{operation.type, operation.name}, walk(operation.selections)}
  end

  defp walk(%Absinthe.Blueprint.Document.Field{} = selection) do
    {selection.name, walk(selection.selections)}
  end

  defp walk(_), do: nil

  defp parse_output([]), do: []

  defp parse_output(output) when is_list(output), do: Enum.map(output, &parse_output/1)

  defp parse_output({{operation_type, operation_name}, fields}) do
    %{
      operation_type: operation_type,
      operation_name: operation_name,
      fields: field_names(fields)
    }
  end

  defp parse_output(_), do: nil

  # `walk/1` returns nil for any selection that is not a field -- a fragment spread or an
  # inline fragment, both legal at the top level of an operation. Mapping over those
  # unguarded raises, and `:telemetry` permanently detaches a handler that raises, so one
  # such query would silently take out GraphQL metrics until the next restart.
  defp field_names(fields) when is_list(fields) do
    Enum.flat_map(fields, fn
      {name, _} when is_binary(name) -> [name]
      _ -> []
    end)
  end

  defp field_names(_), do: []
end
