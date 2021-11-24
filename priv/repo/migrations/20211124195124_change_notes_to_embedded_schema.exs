defmodule Meadow.Repo.Migrations.ChangeNotesToEmbeddedSchema do
  use Ecto.Migration

  alias Meadow.Config
  alias Meadow.Data.CodedTerms
  alias Meadow.Data.Schemas.CodedTerm
  alias Meadow.Repo

  import Ecto.Query

  def up do
    Config.priv_path("repo/seeds/coded_terms/note_type.json") |> CodedTerms.seed()

    transform_notes(fn notes ->
      Enum.map(notes, fn note ->
        %{type: %{id: "GENERAL_NOTE", scheme: "note_type"}, note: note}
      end)
    end)
  end

  def down do
    transform_notes(fn notes ->
      Enum.map(notes, fn note -> note["note"] end)
    end)

    from(t in CodedTerm, where: t.scheme == "note_type") |> Repo.delete_all()
  end

  defp transform_notes(transformer) do
    Repo.transaction(fn ->
      from(
        w in "works",
        where: fragment("descriptive_metadata->'notes' IS NOT NULL"),
        select: %{
          id: w.id,
          descriptive_metadata: w.descriptive_metadata
        }
      )
      |> Repo.stream()
      |> Stream.each(fn %{id: work_id, descriptive_metadata: descriptive_metadata} ->
        new_notes = descriptive_metadata["notes"] |> transformer.() |> IO.inspect()
        new_descriptive_metadata = Map.put(descriptive_metadata, "notes", new_notes)
        from(w in "works", where: w.id == ^work_id)
        |> Repo.update_all(set: [descriptive_metadata: new_descriptive_metadata, updated_at: DateTime.utc_now()])
      end)
      |> Stream.run()
    end)
  end
end
