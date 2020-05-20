# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Meadow.Repo.insert!(%Meadow.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Run all modules in priv/repo/seeds/
Path.relative_to_cwd(__ENV__.file)
|> Path.dirname()
|> Path.join("seeds/**/*.exs")
|> Path.wildcard()
|> Enum.each(fn seed_file ->
  case Code.require_file(seed_file) do
    nil -> :noop
    code -> code |> Enum.each(fn {module, _} -> module.run() end)
  end
end)
