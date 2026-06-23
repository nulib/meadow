defmodule Meadow.AI.Provenance.LegacyNotes do
  @moduledoc """
  Report and migrate legacy AI disclosure notes into canonical provenance records.
  """

  import Ecto.Query, warn: false

  alias Meadow.AI.Provenance
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Repo

  @metadata_note ~r/^Some metadata created with the assistance of AI(?: \((?<model>.+)\))? on (?<date>\d{4}-\d{2}-\d{2})$/
  @transcription_note ~r/^Transcription generated for (?<label>.+) by AI(?: \((?<model>.+)\))? on (?<date>\d{4}-\d{2}-\d{2})$/

  def dry_run(opts \\ []) do
    opts
    |> candidates()
    |> Enum.map(&candidate_report/1)
  end

  def apply(opts \\ []) do
    opts
    |> candidates()
    |> Enum.map(&apply_candidate/1)
  end

  def candidates(_opts \\ []) do
    Work
    |> Repo.all()
    |> Enum.flat_map(&recognized_notes/1)
  end

  defp recognized_notes(%Work{} = work) do
    work
    |> notes()
    |> Enum.flat_map(fn note ->
      case parse_note(note_text(note)) do
        nil -> []
        parsed -> [%{work: work, note: note, parsed: parsed}]
      end
    end)
  end

  defp parse_note(text) when is_binary(text) do
    cond do
      captures = Regex.named_captures(@metadata_note, text) ->
        %{
          note_type: "metadata",
          field_path: "descriptive_metadata",
          model: blank_to_nil(captures["model"]),
          date: captures["date"]
        }

      captures = Regex.named_captures(@transcription_note, text) ->
        %{
          note_type: "transcription",
          field_path: "file_set_annotations.content",
          model: blank_to_nil(captures["model"]),
          date: captures["date"]
        }

      true ->
        nil
    end
  end

  defp parse_note(_), do: nil

  defp candidate_report(%{work: work, note: note, parsed: parsed}) do
    %{
      work_id: work.id,
      accession_number: work.accession_number,
      note_text: note_text(note),
      parsed_model: parsed.model,
      parsed_date: parsed.date,
      candidate_field_paths: [parsed.field_path],
      cleanup_action: "create legacy_ai_note_detected provenance and remove recognized note"
    }
  end

  defp apply_candidate(%{work: work, note: note, parsed: parsed} = candidate) do
    {:ok, report} =
      Repo.transaction(fn ->
        activity =
          %{
            activity_type: "legacy_note_cleanup",
            model: parsed.model,
            ai_use_type: "metadata_migration",
            access_mode: "internal_audit",
            reversibility: "reversible",
            input: %{note: note_text(note)},
            work_id: work.id,
            status: "completed",
            completed_at: parsed_datetime(parsed.date)
          }
          |> Provenance.create_activity()
          |> unwrap_or_rollback()

        target =
          Provenance.add_target(activity, %{
            target_type: "Work",
            target_id: work.id,
            field_path: parsed.field_path,
            operation: "legacy_note",
            proposed_value: note_text(note),
            origin: "legacy_ai_note_detected",
            status: "legacy",
            premis_object_category: "intellectual_entity",
            object_identifier_type: "Meadow Work",
            object_identifier_value: work.id
          })
          |> unwrap_or_rollback()

        Provenance.add_event(target, %{
          event_type: "legacy_note_migrated",
          occurred_at: parsed_datetime(parsed.date),
          value_after: note_text(note)
        })
        |> unwrap_or_rollback()

        remove_note!(work, note)
        candidate_report(candidate)
      end)

    report
  end

  defp remove_note!(work, note_to_remove) do
    remaining_notes =
      work
      |> notes()
      |> Enum.reject(&(note_identity(&1) == note_identity(note_to_remove)))
      |> Enum.map(&note_to_attrs/1)

    work
    |> Works.update_work(%{descriptive_metadata: %{notes: remaining_notes}})
    |> unwrap_or_rollback()
  end

  defp notes(%Work{descriptive_metadata: %{notes: notes}}) when is_list(notes), do: notes
  defp notes(_), do: []

  defp note_text(%{note: note}), do: note
  defp note_text(%{"note" => note}), do: note
  defp note_text(_), do: nil

  defp note_identity(note) do
    attrs = note_to_attrs(note)
    type = Map.get(attrs, :type) || Map.get(attrs, "type") || %{}
    type_id = Map.get(type, :id) || Map.get(type, "id")

    {note_text(note), type_id}
  end

  defp note_to_attrs(%_{} = note), do: note |> Map.from_struct() |> note_to_attrs()

  defp note_to_attrs(%{type: %_{} = type} = note) do
    note
    |> Map.put(:type, Map.from_struct(type))
    |> note_to_attrs()
  end

  defp note_to_attrs(%{type: type, note: text}), do: %{note: text, type: type}
  defp note_to_attrs(%{"type" => type, "note" => text}), do: %{note: text, type: type}

  defp parsed_datetime(nil), do: DateTime.utc_now()

  defp parsed_datetime(date) do
    case Date.from_iso8601(date) do
      {:ok, date} -> DateTime.from_naive!(NaiveDateTime.new!(date, ~T[00:00:00]), "Etc/UTC")
      _ -> DateTime.utc_now()
    end
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: Repo.rollback(reason)
end
