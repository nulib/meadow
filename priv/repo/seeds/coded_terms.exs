defmodule Meadow.Repo.Seeds.CodedTerms do
  alias Meadow.Data.Schemas.CodedTerm
  alias Meadow.Repo

  require Logger

  def run do
    old_level = Logger.level()
    try do
      Logger.configure(level: :info)
      Path.relative_to_cwd(__ENV__.file)
      |> Path.dirname()
      |> Path.join("coded_terms/*.json")
      |> Path.wildcard()
      |> Enum.each(&seed/1)
    after
      Logger.configure(level: old_level)
    end
  end

  def seed(file) do
    with scheme <- Path.basename(file, ".json") do
      Logger.info("Seeding #{scheme} scheme")
      seed_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      data = File.read!(file)
             |> Jason.decode!(keys: :atoms)
             |> Enum.map(fn term ->
               Map.merge(term, %{scheme: scheme, inserted_at: seed_time, updated_at: seed_time})
             end)
      Repo.insert_all(CodedTerm, data, on_conflict: :replace_all, conflict_target: [:id, :scheme])
    end
  end
end
