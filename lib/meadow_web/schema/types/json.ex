defmodule MeadowWeb.Schema.Types.Json do
  @moduledoc """
  The Json scalar type allows arbitrary JSON values to be passed in and out.
  Requires `{ :jason, "~> 1.1" }` package: https://github.com/michalmuskala/jason
  """
  use Absinthe.Schema.Notation

  scalar :json, name: "Json" do
    description("""
    The `Json` scalar type represents arbitrary json string data, represented as UTF-8
    character sequences. The Json type is most often used to represent a free-form
    human-readable json string.
    """)

    serialize(&encode_json/1)
    parse(&decode_json/1)
  end

  @spec decode_json(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode_json(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode_json(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode_json(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode_json(_) do
    :error
  end

  defp encode_json(value), do: value
end
