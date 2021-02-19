defmodule Meadow.Repo.Seeds.Fields do
  alias Meadow.Data.Schemas.Field
  alias Meadow.Repo

  require Logger

  def run do
    Path.relative_to_cwd(__ENV__.file)
    |> Path.dirname()
    |> Path.join("fields.json")
    |> seed()
  end

  def seed(file) do
    Logger.info("Seeding fields")
    seed_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    data = File.read!(file)
            |> Jason.decode!(keys: :atoms)
            |> Enum.map(fn field ->
              Map.merge(field, %{inserted_at: seed_time, updated_at: seed_time})
            end)
    Repo.insert_all(Field, data, on_conflict: :replace_all, conflict_target: [:id])
  end
end
