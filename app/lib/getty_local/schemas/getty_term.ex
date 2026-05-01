defmodule GettyLocal.Schemas.GettyTerm do
  @moduledoc """
  Schema for Getty local authority records, which are stored in the `getty_terms` table.
  """
  use Ecto.Schema

  @primary_key false
  schema "getty_vocab" do
    field(:authority, :string, primary_key: true)
    field(:uri, :string, primary_key: true)
    field(:label, :string)
    field(:hint, :string)
    field(:qualified_label, :string)
    field(:variants, :string)
  end
end
