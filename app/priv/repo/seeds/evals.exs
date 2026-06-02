alias Meadow.Evals
# Seed the default "match_all" eval query for dev/test environments
case Evals.get_eval_query_by_name("match_all") do
  nil ->
    {:ok, _} =
      Evals.create_eval_query(%{
        name: "match_all",
        description: "Match all works in the index. Use for dev/test environments.",
        query_json: %{"query" => %{"match_all" => %{}}},
        author: "system"
      })

    IO.puts("Evals: created match_all query")

  _ ->
    IO.puts("Evals: match_all query already exists, skipping")
end

# Seed the initial prompt version from the current GenerateAIMetadata prompts
case Evals.latest_prompt_version() do
  nil ->
    {:ok, _} =
      Evals.create_prompt_version(%{
        name: "v1 — initial (from GenerateAIMetadata)",
        subject_prompt: Evals.default_subject_prompt(),
        description_prompt: Evals.default_description_prompt(),
        author: "system",
        change_notes: "Initial version seeded from GenerateAIMetadata action prompts"
      })

    IO.puts("Evals: created initial prompt version")

  _ ->
    IO.puts("Evals: prompt version already exists, skipping")
end
