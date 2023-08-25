defmodule Meadow.Ark do
  @moduledoc """
  Functions to create and manipulate ARKs using the EZID API
  """

  alias Meadow.Ark.{Client, Serializer}
  alias Meadow.Config
  alias Meadow.Data.Schemas.ArkCache
  alias Meadow.Repo

  import Ecto.Query

  require Logger

  defstruct ark: nil,
            creator: nil,
            title: nil,
            publisher: nil,
            publication_year: nil,
            resource_type: nil,
            status: nil,
            target: nil,
            work_id: nil

  def from_attrs(attributes), do: struct!(__MODULE__, Enum.into(attributes, []))

  @doc """
  Mint a new ARK identifier

  ## Examples:

   iex> mint()
   {:ok,
    %Meadow.Ark{
      ark: "ark:/99999/fk4xd27r9t",
      creator: nil,
      publication_year: nil,
      publisher: nil,
      resource_type: nil,
      status: nil,
      target: nil,
      title: nil
    }}

   iex> mint(%Meadow.Ark{title: "Work Title", creator: "Work Creator", resource_type: "Image", target: "https://example.edu/resource"})
   {:ok,
    %Meadow.Ark{
      ark: "ark:/99999/fk4n31617m",
      creator: "Work Creator",
      publication_year: nil,
      publisher: nil,
      resource_type: "Image",
      status: nil,
      target: "https://example.edu/resource",
      title: "Work Title"
    }}

   iex> mint(title: "Work Title", creator: "Work Creator", resource_type: "Image", target: "https://example.edu/resource")
   {:ok,
    %Meadow.Ark{
      ark: "ark:/99999/fk4n31617m",
      creator: "Work Creator",
      publication_year: nil,
      publisher: nil,
      resource_type: "Image",
      status: nil,
      target: "https://example.edu/resource",
      title: "Work Title"
    }}
  """
  def mint(arg \\ [])

  def mint(%__MODULE__{} = ark) do
    with shoulder <- Config.ark_config() |> Map.get(:default_shoulder) do
      case Client.post("/shoulder/#{shoulder}", Serializer.serialize(ark)) do
        {:ok, %{status_code: status, body: body}} when status in 200..201 ->
          new_id = Serializer.deserialize(body) |> Map.get(:ark)
          ark = Map.put(ark, :ark, new_id)
          put_in_cache(ark)
          {:ok, ark}

        {:ok, %{body: body}} ->
          {:error, body}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  def mint(attributes) do
    mint(struct!(__MODULE__, Enum.into(attributes, [])))
  end

  @doc """
  Retrieve the metadata for an ARK identifier

  ## Examples:

   iex> get("ark:/99999/fk4n31617m")
   {:ok,
    %Meadow.Ark{
      ark: "ark:/99999/fk4n31617m",
      creator: "Work Creator",
      publication_year: nil,
      publisher: nil,
      resource_type: "Image",
      status: "public",
      target: "https://example.edu/resource",
      title: "Work Title"
    }}

   iex> get("ark:/99999/fk4unknown")
   {:error, "error: bad request - no such identifier"}
  """
  def get(id) do
    case get_from_cache(id) do
      nil ->
        case get_from_source(id) do
          {:ok, ark} ->
            put_in_cache(ark)
            {:ok, ark}

          other ->
            other
        end

      ark ->
        {:ok, ark}
    end
  end

  def get_from_source(id) do
    Logger.debug("Retrieving ark #{id} from source")

    case Client.get("/id/#{id}") do
      {:ok, %{status_code: 200, body: body}} -> {:ok, Serializer.deserialize(body)}
      {:ok, %{body: body}} -> {:error, body}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Update the metadata for an ARK identifier

  ## Examples:
   iex> with {:ok, ark} <- get("ark:/99999/fk4n31617m") do
   ...>   ark |> Map.merge(%{publisher: "Work Publisher", publication_year: "2020"}) |> put()
   ...> end
   {:ok,
    %Meadow.Ark{
      ark: "ark:/99999/fk4n31617m",
      creator: "Work Creator",
      publication_year: "2020",
      publisher: "Work Publisher",
      resource_type: "Image",
      status: "public",
      target: "https://example.edu/resource",
      title: "Work Title"
    }}
  """
  def put(%__MODULE__{ark: nil}) do
    {:error, "cannot update an ARK without an ID"}
  end

  def put(%__MODULE__{} = ark) do
    case Client.post("/id/#{ark.ark}", Serializer.serialize(ark)) do
      {:ok, %{status_code: status}} when status in 200..201 ->
        put_in_cache(ark)
        {:ok, ark}

      {:ok, %{body: body}} ->
        {:error, body}

      {:error, error} ->
        {:error, error}
    end
  end

  def put(attributes), do: from_attrs(attributes) |> put()

  @doc """
  Remove the ARK identifier

  ## Examples:

   iex> delete("ark:/99999/fk4n31617m")
   {:ok,true}}

   iex> delete("ark:/99999/fk4unknown")
   {:error, "error: bad request - no such identifier"}
  """
  def delete(id) do
    case Client.delete("/id/#{id}") do
      {:ok, %{status_code: 200, body: body}} ->
        delete_from_cache(id)
        {:ok, Serializer.deserialize(body)}

      other ->
        other
    end
  end

  def digest(%__MODULE__{} = ark), do: :crypto.hash(:md5, Serializer.serialize(ark))
  def digest(attributes), do: from_attrs(attributes) |> digest()

  def clear_cache, do: ArkCache |> Repo.delete_all()

  def delete_from_cache(id) do
    from(c in ArkCache, where: c.ark == ^id)
    |> Repo.delete_all()
  end

  def get_from_cache(id) do
    Logger.debug("Retrieving ark #{id} from cache")

    from(c in ArkCache, where: c.ark == ^id)
    |> Repo.one()
    |> from_cache()
  end

  def put_in_cache(ark) do
    from(c in ArkCache, where: c.ark == ^ark.ark)
    |> Repo.one()
    |> ArkCache.changeset(Map.from_struct(ark))
    |> Repo.insert_or_update()
  end

  def from_cache(nil), do: nil

  def from_cache(%ArkCache{} = cache) do
    cache
    |> Map.from_struct()
    |> Enum.reject(fn {_, v} -> not is_binary(v) end)
    |> from_attrs()
  end
end
