defmodule Meadow.Data.AuditEntries do
  @moduledoc """
  The AuditEntries context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.AuditEntries.AuditEntry
  alias Meadow.Ingest.IngestSheets.IngestSheetProgress
  alias Meadow.Repo

  def latest_outcome(object_id) do
    case get_latest_entry(object_id) do
      %AuditEntry{outcome: outcome} -> outcome
      _ -> :unknown
    end
  end

  def error?(object_id),
    do: get_entries(object_id) |> Enum.any?(fn entry -> entry.outcome == "error" end)

  def ok?(object_id),
    do: get_entries(object_id) |> Enum.all?(fn entry -> entry.outcome == "ok" end)

  def latest_outcome(object_id, action) do
    case get_latest_entry(object_id, action) do
      %AuditEntry{outcome: outcome} -> outcome
      _ -> :unknown
    end
  end

  def error?(object_id, action), do: latest_outcome(object_id, action) == "error"
  def ok?(object_id, action), do: latest_outcome(object_id, action) == "ok"

  def initialize_entries(object, actions, initial_status \\ "waiting")

  def initialize_entries({object_type, object_id}, actions, initial_status) do
    Repo.transaction(fn ->
      actions
      |> Enum.each(fn action ->
        add_entry!({object_type, object_id}, action, initial_status)
      end)
    end)
  end

  def initialize_entries(object, actions, initial_status) do
    {object.__struct__, object.id}
    |> initialize_entries(actions, initial_status)
  end

  def get_entry!(id) do
    from(a in AuditEntry, where: a.id == ^id) |> Repo.one()
  end

  def get_latest_entry(object_id) do
    from(
      entries(object_id),
      limit: 1
    )
    |> Repo.one()
  end

  def get_latest_entry(object_id, action) do
    from(
      a in entries(object_id),
      where: a.action == ^AuditEntry.atom_to_string(action),
      limit: 1
    )
    |> Repo.one()
  end

  def get_entries(object_id) do
    entries(object_id)
    |> Repo.all()
  end

  def add_entry(object, action, outcome, notes \\ nil)

  def add_entry({object_type, object_id}, action, outcome, notes) do
    make_changeset(object_type, object_id, action, outcome, notes)
    |> Repo.insert(
      on_conflict: [set: [outcome: outcome, notes: notes, updated_at: DateTime.utc_now()]],
      conflict_target: [:object_id, :action]
    )
    |> send_audit_notification()
  end

  def add_entry(object, action, outcome, notes) do
    {object.__struct__, object.id}
    |> add_entry(action, outcome, notes)
  end

  def add_entry!(object, action, outcome, notes \\ nil)

  def add_entry!({object_type, object_id}, action, outcome, notes) do
    make_changeset(object_type, object_id, action, outcome, notes)
    |> Repo.insert!(
      on_conflict: [set: [outcome: outcome, notes: notes, updated_at: DateTime.utc_now()]],
      conflict_target: [:object_id, :action]
    )
    |> send_audit_notification()
  end

  def add_entry!(object, action, outcome, notes) do
    {object.__struct__, object.id}
    |> add_entry!(action, outcome, notes)
  end

  defp entries(object_id) do
    from(a in AuditEntry,
      where: a.object_id == ^object_id,
      order_by: [desc: :updated_at, desc: :id]
    )
  end

  defp make_changeset(object_type, object_id, action, outcome, notes) do
    %AuditEntry{}
    |> AuditEntry.changeset(%{
      object_type: object_type,
      object_id: object_id,
      action: action,
      outcome: outcome,
      notes: notes
    })
  end

  # Absinthe Notifications

  defp send_audit_notification({:ok, entry}),
    do: {:ok, send_audit_notification(entry)}

  defp send_audit_notification(%AuditEntry{} = entry) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      entry,
      audit_update: entry.object_id,
      audit_updates: :all
    )

    IngestSheetProgress.send_notification(entry)

    entry
  end
end
