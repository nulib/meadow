defmodule Meadow.Data.ActionStates do
  @moduledoc """
  The ActionStates context.
  """

  import Ecto.Query, warn: false
  import Meadow.Utils.Atoms

  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Repo

  @ok_states ["ok", "n/a"]

  def latest_outcome(object_id) do
    case get_latest_state(object_id) do
      %ActionState{outcome: outcome} -> outcome
      _ -> :unknown
    end
  end

  def error?(object_id),
    do: get_states(object_id) |> Enum.any?(fn state -> state.outcome == "error" end)

  def ok?(object_id),
    do: get_states(object_id) |> Enum.all?(fn state -> Enum.member?(@ok_states, state.outcome) end)

  def latest_outcome(object_id, action) do
    case get_latest_state(object_id, action) do
      %ActionState{outcome: outcome} -> outcome
      _ -> :unknown
    end
  end

  def error?(object_id, action), do: latest_outcome(object_id, action) == "error"
  def ok?(object_id, action), do: Enum.member?(@ok_states, latest_outcome(object_id, action))

  def initialize_states(object, actions, initial_status \\ "waiting")

  def initialize_states({object_type, object_id}, actions, initial_status) do
    Repo.transaction(fn ->
      actions
      |> Enum.each(fn action ->
        set_state!({object_type, object_id}, action, initial_status)
      end)
    end)
  end

  def initialize_states(object, actions, initial_status) do
    {object.__struct__, object.id}
    |> initialize_states(actions, initial_status)
  end

  def get_state!(id) do
    from(a in ActionState, where: a.id == ^id) |> Repo.one()
  end

  def get_latest_state(object_id) do
    from(
      states(object_id),
      limit: 1
    )
    |> Repo.one()
  end

  def get_latest_state(object_id, action) do
    from(
      a in states(object_id),
      where: a.action == ^atom_to_string(action),
      limit: 1
    )
    |> Repo.one()
  end

  def get_states(object_id) do
    states(object_id)
    |> Repo.all()
  end

  def set_state(object, action, outcome, notes \\ nil)

  def set_state(object, action, outcome, notes) when not is_nil(notes) and not is_binary(notes) do
    set_state(object, action, outcome, coerce_to_string(notes))
  end

  def set_state({object_type, object_id}, action, outcome, notes) do
    make_changeset(object_type, object_id, action, outcome, notes)
    |> Repo.insert(
      on_conflict: [set: [outcome: outcome, notes: notes, updated_at: DateTime.utc_now()]],
      conflict_target: [:object_id, :action]
    )
  end

  def set_state(object, action, outcome, notes) do
    {object.__struct__, object.id}
    |> set_state(action, outcome, notes)
  end

  def set_state!(object, action, outcome, notes \\ nil)

  def set_state!(object, action, outcome, notes)
      when not is_nil(notes) and not is_binary(notes) do
    set_state!(object, action, outcome, coerce_to_string(notes))
  end

  def set_state!({object_type, object_id}, action, outcome, notes) do
    make_changeset(object_type, object_id, action, outcome, notes)
    |> Repo.insert!(
      on_conflict: [set: [outcome: outcome, notes: notes, updated_at: DateTime.utc_now()]],
      conflict_target: [:object_id, :action]
    )
  end

  def set_state!(object, action, outcome, notes) do
    {object.__struct__, object.id}
    |> set_state!(action, outcome, notes)
  end

  def abort_remaining_waiting_actions(object_id) do
    from(a in ActionState,
      where: a.object_id == ^object_id and a.outcome == "waiting"
    )
    |> Repo.update_all(set: [outcome: "error", notes: "Previous action failed"])
  end

  defp states(object_id) do
    from(a in ActionState,
      where: a.object_id == ^object_id,
      order_by: [desc: :updated_at, desc: :id]
    )
  end

  defp make_changeset(object_type, object_id, action, outcome, notes) do
    %ActionState{}
    |> ActionState.changeset(%{
      object_type: object_type,
      object_id: object_id,
      action: action,
      outcome: outcome,
      notes: notes
    })
  end

  def coerce_to_string(value) do
    to_string(value)
  rescue
    _ -> inspect(value)
  end
end
