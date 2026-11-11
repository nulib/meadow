defmodule Meadow.TranscriptionBench.Models do
  @moduledoc """
  The Claude models a bench run can be sent to: the inference profiles the account can
  call, or a short list when Bedrock will not say (the role may not list profiles).
  """

  require Logger

  @prefix "us.anthropic.claude-"
  @fallback ~w(
    us.anthropic.claude-sonnet-5-5
    us.anthropic.claude-sonnet-4-6
    us.anthropic.claude-opus-5-5
    us.anthropic.claude-haiku-5-5
  )

  @doc "Models as `%{id: profile_id, label: name}`, newest first."
  def list do
    ids =
      case profiles(nil, []) do
        [] -> @fallback
        found -> found
      end

    ids
    |> Enum.uniq()
    |> Enum.sort_by(&{-version(&1), &1})
    |> Enum.map(&%{id: &1, label: label(&1)})
  end

  defp profiles(next_token, acc) do
    case AWS.Bedrock.list_inference_profiles(Meadow.AWS.client(:bedrock), 100, next_token) do
      {:ok, %{"inferenceProfileSummaries" => summaries} = page, _} ->
        acc =
          acc ++
            for(
              %{"inferenceProfileId" => @prefix <> _ = id} <- summaries,
              do: id
            )

        case page["nextToken"] do
          token when is_binary(token) -> profiles(token, acc)
          _ -> acc
        end

      other ->
        Logger.warning("Could not list Bedrock inference profiles: #{inspect(other)}")
        acc
    end
  rescue
    error ->
      Logger.warning("Could not list Bedrock inference profiles: #{Exception.message(error)}")
      acc
  end

  # claude-sonnet-4-6 and claude-3-5-sonnet-...: major * 10 + minor, to sort newest first.
  defp version(id) do
    case Regex.run(~r/claude-(?:[a-z]+-)?(\d+)(?:-(\d)(?!\d))?/, id) do
      [_, major, minor] -> String.to_integer(major) * 10 + String.to_integer(minor)
      [_, major] -> String.to_integer(major) * 10
      _ -> 0
    end
  end

  @doc "us.anthropic.claude-sonnet-4-6 as \"Sonnet 4.6\"."
  def label(id) do
    id
    |> String.replace(~r/^(us|global|eu|apac)\.anthropic\.claude-/, "")
    |> String.replace(~r/-\d{8}.*$/, "")
    |> String.replace(~r/-v\d+(:\d+)?$/, "")
    |> String.replace(~r/-(\d+)-(\d+)$/, " \\1.\\2")
    |> String.replace(~r/-(\d+)$/, " \\1")
    |> String.replace("-", " ")
    |> String.capitalize()
  end
end
