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

# Run all modules
Path.relative_to_cwd(__ENV__.file)
|> Path.dirname()
|> Path.join("seeds/**/*.exs")
|> Path.wildcard()
|> Enum.each(fn seed_file ->
     Code.compile_file(seed_file)
     |> Enum.each(fn {module, _} -> module.run() end)
   end)
