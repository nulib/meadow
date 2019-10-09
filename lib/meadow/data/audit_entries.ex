defmodule Meadow.Data.AuditEntries do
  @moduledoc """
  The AuditEntries context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.AuditEntries.AuditEntry
  alias Meadow.Repo

  def latest_outcome_for(object_id) do
    case get_latest_entry_for(object_id) do
      %AuditEntry{outcome: outcome} -> outcome
      _ -> nil
    end
  end

  def error?(object_id), do: latest_outcome_for(object_id) == "error"
  def ok?(object_id), do: latest_outcome_for(object_id) == "ok"

  def latest_outcome_for(object_id, action) do
    case get_latest_entry_for(object_id, action) do
      %AuditEntry{outcome: outcome} -> outcome
      _ -> nil
    end
  end

  def error?(object_id, action), do: latest_outcome_for(object_id, action) == "error"
  def ok?(object_id, action), do: latest_outcome_for(object_id, action) == "ok"

  def get_latest_entry_for(object_id) do
    from(
      entries_for(object_id),
      limit: 1
    )
    |> Repo.one()
  end

  def get_latest_entry_for(object_id, action) do
    from(
      a in entries_for(object_id),
      where: a.action == ^AuditEntry.action_to_string(action),
      limit: 1
    )
    |> Repo.one()
  end

  def get_entries_for(object_id) do
    entries_for(object_id)
    |> Repo.all()
  end

  def get_entries_for(object_id, action) do
    from(
      a in entries_for(object_id),
      where: a.action == ^AuditEntry.action_to_string(action)
    )
    |> Repo.all()
  end

  def add_entry(object_id, action, outcome, notes \\ nil),
    do: Repo.insert(make_changeset(object_id, action, outcome, notes))

  def add_entry!(object_id, action, outcome, notes \\ nil),
    do: Repo.insert!(make_changeset(object_id, action, outcome, notes))

  defp entries_for(object_id) do
    from(a in AuditEntry,
      where: a.object_id == ^object_id,
      order_by: [desc: :updated_at]
    )
  end

  defp make_changeset(object_id, action, outcome, notes) when is_nil(notes) or is_binary(notes) do
    %AuditEntry{}
    |> AuditEntry.changeset(%{
      object_id: object_id,
      action: action,
      outcome: outcome,
      notes: notes
    })
  end

  defp make_changeset(object_id, action, outcome, notes),
    do: make_changeset(object_id, action, outcome, inspect(notes))
end
