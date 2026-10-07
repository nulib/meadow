defmodule Meadow.Repo.Migrations.CreateLegacyViews do
  @moduledoc """
  Add the `legacy` schema: read-only views that present `works` and `file_sets`
  with their old jsonb columns reassembled, as a transitional aid for anyone
  reading the database the way it used to look. See `Meadow.Legacy.Views`.

  This runs after the jsonb columns are dropped, so the view's pass-through
  columns cannot collide with the originals.
  """

  use Ecto.Migration

  def up, do: Meadow.Legacy.Views.create!()

  def down, do: Meadow.Legacy.Views.drop!()
end
