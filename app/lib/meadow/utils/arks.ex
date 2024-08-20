defmodule Meadow.Arks do
  @moduledoc """
  High-level context wrapper for Meadow.Ark
  """

  alias Meadow.{Ark, Config}
  alias Meadow.Data.Works
  alias Meadow.Data.Schemas.{ArkCache, ControlledMetadataEntry, Work}
  alias Meadow.Repo

  import Ecto.Query

  require Logger

  @work_type_resource_type_mapping %{
    "AUDIO" => "Sound",
    "VIDEO" => "Audiovisual"
  }

  @doc """
  Retrieves the ARK Target URL for a work
  iex> ark_target_url("f352eb30-ae2f-4b49-81f9-6eb4659a3f47")
  "https://dc.library.northwestern.edu/items/f352eb30-ae2f-4b49-81f9-6eb4659a3f47"

  iex> ark_target_url(%Work{id:"f352eb30-ae2f-4b49-81f9-6eb4659a3f47"})
  "https://dc.library.northwestern.edu/items/f352eb30-ae2f-4b49-81f9-6eb4659a3f47"

  """
  def ark_target_url(%Work{id: id}) do
    ark_target_url(id)
  end

  def ark_target_url(work_id) do
    Map.get(Config.ark_config(), :target_url) <> work_id
  end

  @doc """
  Mints an ARK for a work
  iex> mint_ark(work)
  {:ok,
   %Work{
     ...
     descriptive_metadata: %WorkDescriptiveMetadata{
       ...
       ark: "ark:/99999/fk4newark"
     }
   }}

  iex> mint_ark(work_with_existing_ark)
  {:noop,
   %Work{...}}
  """
  def mint_ark(%Work{descriptive_metadata: %{ark: ark}} = work)
      when not is_nil(ark) do
    Logger.warning("Not minting ARK for work #{work.id} because it already has one: #{ark}")
    {:noop, work}
  end

  def mint_ark(nil), do: {:noop, nil}

  def mint_ark(%Work{} = work) do
    Logger.info("Minting ARK for work #{work.id}")

    case work |> initial_ark() |> Ark.mint() do
      {:ok, result} ->
        Logger.info("Minted ARK #{result.ark} for work #{work.id}")
        Works.update_work(work, %{descriptive_metadata: %{ark: result.ark}})

      {:error, error_message} ->
        Meadow.Error.report(error_message, __MODULE__, [], %{work_id: work.id})
        {:error, error_message}
    end
  end

  def initial_ark(work) do
    work |> initial_ark_attributes() |> Ark.from_attrs()
  end

  def update_ark_metadata(%Work{} = work) do
    case existing_ark(work) do
      {:error, message} ->
        {:error, message}

      {:ok, %{status: current_status} = existing} ->
        with new_status <- ark_update_status(current_status, work),
             ark <- ark(work, status: new_status) do
          work |> update_existing_ark(existing, ark)
        end
    end
  end

  defp update_existing_ark(_work, ark, ark) do
    Logger.debug("Metadata for #{ark.ark} didn't change. Not sending update.")
    :noop
  end

  defp update_existing_ark(
         work,
         %{status: "reserved"} = old,
         %{status: "unavailable" <> _} = new
       ) do
    Logger.debug(
      "#{new.ark} transitioning from reserved to unavailable - must go through public."
    )

    case update_existing_ark(work, old, %Ark{old | status: "public"}) do
      {:ok, intermediate} -> update_existing_ark(work, intermediate, new)
      other -> other
    end
  end

  defp update_existing_ark(work, _, ark) do
    Logger.info("Updating ARK #{ark.ark} for work #{work.id}")

    case Ark.put(ark) do
      {:ok, result} ->
        Logger.info("Ark successfully updated. #{inspect(result)}")
        {:ok, result}

      {:error, error_message} ->
        Meadow.Error.report(error_message, __MODULE__, [], %{work_id: work.id})
        {:error, error_message}
    end
  end

  def existing_ark(work) do
    case work.descriptive_metadata.cached_ark do
      %ArkCache{} = cached -> {:ok, Ark.from_cache(cached)}
      _ -> Ark.get(work.descriptive_metadata.ark)
    end
  end

  def ark(work, attrs \\ []) do
    work |> ark_attributes(attrs) |> Ark.from_attrs()
  end

  def ark_attributes(work, attrs) do
    Keyword.merge(
      [
        ark: work.descriptive_metadata.ark,
        creator: scalar_value(work.descriptive_metadata.creator),
        title: work.descriptive_metadata.title,
        publisher: scalar_value(work.descriptive_metadata.publisher),
        publication_year: nil,
        resource_type: resource_type(work),
        target: ark_target_url(work),
        work_id: work.id
      ],
      attrs
    )
  end

  defp initial_ark_attributes(work) do
    status =
      case work do
        %{published: true, visibility: %{id: "RESTRICTED"}} -> "unavailable | restricted"
        %{published: true} -> "public"
        _ -> "reserved"
      end

    ark_attributes(work, status: status)
  end

  defp resource_type(%{work_type: nil}), do: nil

  defp resource_type(%{work_type: %{id: work_type}}) do
    case Map.get(@work_type_resource_type_mapping, work_type) do
      nil -> work_type |> String.downcase() |> Inflex.Camelize.camelize()
      value -> value
    end
  end

  defp scalar_value([%ControlledMetadataEntry{term: %{label: value}} | _]), do: value
  defp scalar_value([value | _]), do: value
  defp scalar_value(%{label: value}), do: value
  defp scalar_value([]), do: nil
  defp scalar_value(value), do: value

  def mint_ark!(work) do
    case mint_ark(work) do
      {:noop, work} -> work
      {:ok, work} -> work
      {_, other} -> raise other
    end
  end

  defp ark_update_status("reserved", %{published: false}), do: "reserved"
  defp ark_update_status(_, %{published: false}), do: "unavailable | unpublished"
  defp ark_update_status(_, %{visibility: %{id: "RESTRICTED"}}), do: "unavailable | restricted"
  defp ark_update_status(_, _), do: "public"

  def delete_ark(ark) do
    Ark.delete(ark.ark)
  end

  def work_deleted(work_id) do
    case from(c in ArkCache, where: c.work_id == ^work_id)
         |> Repo.one()
         |> Ark.from_cache() do
      nil -> :noop
      %{status: "reserved"} = ark -> delete_ark(ark)
      ark -> Ark.put(%Ark{ark | status: "unavailable | withdrawn", work_id: nil})
    end
  end
end
