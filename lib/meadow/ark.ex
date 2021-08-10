defmodule Meadow.Ark do
  @moduledoc """
  Functions to create and manipulate ARKs using the EZID API
  """

  alias Meadow.Ark.Client
  alias Meadow.Config

  defstruct ark: nil,
            creator: nil,
            title: nil,
            publisher: nil,
            publication_year: nil,
            resource_type: nil,
            status: nil,
            target: nil

  @datacite_map %{
    ark: "success",
    creator: "datacite.creator",
    title: "datacite.title",
    publisher: "datacite.publisher",
    publication_year: "datacite.publicationyear",
    resource_type: "datacite.resourcetype",
    status: "_status",
    target: "_target"
  }

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
      case Client.post("/shoulder/#{shoulder}", serialize(ark)) do
        {:ok, %{status_code: status, body: body}} when status in 200..201 ->
          new_id = deserialize(body) |> Map.get(:ark)
          {:ok, Map.put(ark, :ark, new_id)}

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
    case Client.get("/id/#{id}") do
      {:ok, %{status_code: 200, body: body}} -> {:ok, deserialize(body)}
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
    case Client.put("/id/#{ark.ark}?update_if_exists=yes", serialize(ark)) do
      {:ok, %{status_code: status}} when status in 200..201 -> {:ok, ark}
      {:ok, %{body: body}} -> {:error, body}
      {:error, error} -> {:error, error}
    end
  end

  defp deserialize(response) do
    field_map =
      Map.values(@datacite_map)
      |> Enum.zip(Map.keys(@datacite_map))
      |> Enum.into(%{})

    struct!(
      __MODULE__,
      response
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(fn attribute ->
        [key, value] = String.split(attribute, ": ", parts: 2)
        {Map.get(field_map, key), URI.decode(value)}
      end)
      |> Enum.reject(fn {key, _} -> is_nil(key) end)
    )
  end

  defp serialize(%__MODULE__{} = ark), do: serialize(Map.from_struct(ark))

  defp serialize(ark) when is_map(ark) do
    Enum.reduce(ark, ["_profile: datacite"], fn
      {_, nil}, acc -> acc
      {:ark, _}, acc -> acc
      entry, acc -> [serialize(entry) | acc]
    end)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp serialize({key, value}) when is_atom(key), do: Map.get(@datacite_map, key) <> ": " <> URI.encode(value)
end
