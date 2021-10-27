defmodule Meadow.Ark do
  @moduledoc """
  Functions to create and manipulate ARKs using the EZID API
  """

  alias Meadow.Ark.{Client, Serializer}
  alias Meadow.Config

  defstruct ark: nil,
            creator: nil,
            title: nil,
            publisher: nil,
            publication_year: nil,
            resource_type: nil,
            status: nil,
            target: nil

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
    case Client.put("/id/#{ark.ark}?update_if_exists=yes", Serializer.serialize(ark)) do
      {:ok, %{status_code: status}} when status in 200..201 -> {:ok, ark}
      {:ok, %{body: body}} -> {:error, body}
      {:error, error} -> {:error, error}
    end
  end

  def put(attributes) do
    put(struct!(__MODULE__, Enum.into(attributes, [])))
  end

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
      {:ok, %{status_code: 200, body: body}} -> {:ok, Serializer.deserialize(body)}
    end
  end
end
