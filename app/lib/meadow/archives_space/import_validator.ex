defmodule Meadow.ArchivesSpace.ImportValidator do
  @moduledoc """
  Validates whether an ArchivesSpace resource is safe to import into Meadow.

  Finding aid records may already have digital objects that point back to
  Northwestern Digital Collections. Those are public record links, not source
  image files, and importing them would feed Meadow's own item pages back into
  the ingest pipeline.
  """

  alias Meadow.ArchivesSpace.{Client, Importer}
  alias Meadow.Config

  require Logger

  @default_levels ~w(file item)
  @sample_limit 5

  def validate(resource_uri, opts \\ []) do
    levels = Keyword.get(opts, :levels, @default_levels)

    with {:ok, uris} <- Importer.archival_object_uris(resource_uri) do
      blocked =
        uris
        |> Enum.flat_map(&blocked_samples_for(&1, levels))

      {:ok, result(blocked)}
    end
  end

  def ensure_importable(resource_uri, opts \\ []) do
    with {:ok, %{importable: true}} <- validate(resource_uri, opts) do
      :ok
    else
      {:ok, validation} -> {:error, blocked_message(validation)}
      other -> other
    end
  end

  defp result([]) do
    %{
      importable: true,
      blocked_reason: nil,
      blocked_count: 0,
      blocked_samples: []
    }
  end

  defp result(blocked) do
    %{
      importable: false,
      blocked_reason:
        "This finding aid already contains digital object links to Digital Collections/ARK records. Importing it would re-ingest Meadow records as source files.",
      blocked_count: length(blocked),
      blocked_samples: Enum.take(blocked, @sample_limit)
    }
  end

  defp blocked_message(%{blocked_reason: reason}), do: reason

  defp blocked_samples_for(uri, levels) do
    with {:ok, archival_object} <- Client.get_record(uri),
         true <- Map.get(archival_object, "level") in levels do
      archival_object
      |> digital_object_file_versions()
      |> Enum.filter(&blocked_file_uri?/1)
      |> Enum.map(fn file_uri ->
        %{
          uri: uri,
          title: archival_object["display_string"] || archival_object["title"],
          file_uri: file_uri
        }
      end)
    else
      _ -> []
    end
  end

  defp digital_object_file_versions(archival_object) do
    archival_object
    |> Map.get("instances", [])
    |> Enum.filter(&(Map.get(&1, "instance_type") == "digital_object"))
    |> Enum.flat_map(fn instance ->
      instance
      |> get_in(["digital_object", "ref"])
      |> file_uris()
    end)
  end

  defp file_uris(nil), do: []

  defp file_uris(ref) do
    case Client.get_record(ref) do
      {:ok, %{"file_versions" => versions}} when is_list(versions) ->
        versions
        |> Enum.map(&Map.get(&1, "file_uri"))
        |> Enum.filter(&is_binary/1)

      {:ok, _record} ->
        []

      {:error, reason} ->
        Logger.warning(
          "Could not inspect ArchivesSpace digital object #{ref}: #{inspect(reason)}"
        )

        []
    end
  end

  defp blocked_file_uri?(file_uri) when is_binary(file_uri) do
    n2t_ark?(file_uri) or dc_item_url?(file_uri) or configured_dc_item_url?(file_uri)
  end

  defp n2t_ark?(file_uri) do
    case URI.parse(file_uri) do
      %URI{host: "n2t.net", path: "ark:" <> _} -> true
      %URI{host: "n2t.net", path: "/ark:" <> _} -> true
      _ -> false
    end
  end

  defp dc_item_url?(file_uri) do
    case URI.parse(file_uri) do
      %URI{host: "dc.library.northwestern.edu", path: "/items/" <> _} -> true
      _ -> false
    end
  end

  defp configured_dc_item_url?(file_uri) do
    base = URI.parse(Config.digital_collections_url())
    uri = URI.parse(file_uri)

    is_binary(base.host) and uri.host == base.host and
      String.starts_with?(uri.path || "", item_path_prefix(base.path))
  end

  defp item_path_prefix(nil), do: "/items/"
  defp item_path_prefix(""), do: "/items/"

  defp item_path_prefix(path) do
    String.trim_trailing(path, "/") <> "/items/"
  end
end
