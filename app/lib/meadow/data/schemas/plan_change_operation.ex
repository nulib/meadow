defmodule Meadow.Data.Schemas.PlanChangeOperation do
  @moduledoc """
  One proposed value of a plan change (`plan_change_operations`): the
  `operation` (add, delete or replace), the target field (`section` is
  `descriptive_metadata`/`administrative_metadata`, or nil for top-level work
  fields), the item's `position` for repeating fields, and the value in typed
  columns selected by `value_kind`. `Meadow.Data.Planner.Operations` converts
  between rows and the `%{add: %{...}, delete: %{...}, replace: %{...}}` maps
  the planner, the MCP tools and the UI exchange.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @operations ~w(add delete replace)
  @value_kinds ~w(string controlled coded edtf note related_url boolean null)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "plan_change_operations" do
    belongs_to :plan_change, Meadow.Data.Schemas.PlanChange
    field :operation, :string
    field :section, :string
    field :field, :string
    field :position, :integer
    field :value_kind, :string
    field :value_text, :string
    field :term_id, :string
    field :term_label, :string
    field :role_id, :string
    field :role_scheme, :string
    field :role_label, :string
    field :coded_id, :string
    field :coded_scheme, :string
    field :coded_label, :string
    field :edtf, :string
    field :humanized, :string
  end

  def operations, do: @operations
  def value_kinds, do: @value_kinds

  def changeset(operation, params) do
    operation
    |> cast(params, __schema__(:fields) -- [:id, :plan_change_id])
    |> validate_required([:operation, :field, :value_kind])
    |> validate_inclusion(:operation, @operations)
    |> validate_inclusion(:value_kind, @value_kinds)
  end
end
