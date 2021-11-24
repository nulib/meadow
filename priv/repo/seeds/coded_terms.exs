defmodule Meadow.Repo.Seeds.CodedTerms do
  alias Meadow.Data.CodedTerms
  alias Meadow.Repo

  def run do
    Path.relative_to_cwd(__ENV__.file)
    |> Path.dirname()
    |> Path.join("coded_terms/*.json")
    |> Path.wildcard()
    |> Enum.each(&CodedTerms.seed/1)
  end
end
