defmodule Mix.Tasks.Graphql.Schema.Export do
  @moduledoc """
  Export the Meadow GraphQL schema as JSON

  ## Command line options

    * `--out PATH, -o PATH` - path to save JSON schema to (default: `stdout`)
  """

  @gql __ENV__.file |> Path.dirname() |> Path.join("introspection.gql")

  def run(args) do
    [:telemetry] |> Enum.each(&Application.ensure_all_started/1)

    parsed_opts =
      with {opts, _} <- OptionParser.parse!(args, aliases: [o: :out], strict: [out: :string]) do
        opts
        |> Enum.into(%{out: nil})
      end

    with {:ok, query} <- File.read(@gql),
         {:ok, schema} <- Absinthe.run(query, MeadowWeb.Schema),
         {:ok, encoded} <- Jason.encode_to_iodata(schema),
         json <- Jason.Formatter.pretty_print(encoded) do
      case parsed_opts do
        %{out: nil} ->
          IO.puts(json)

        %{out: path} ->
          path |> Path.dirname() |> File.mkdir_p!()
          File.write(path, json)
      end
    end
  end
end
