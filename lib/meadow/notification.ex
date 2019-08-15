defmodule Meadow.Notification do
  @moduledoc """
  Handles Phoenix channel notifications, synchronized with ETS.
  """

  @derive Jason.Encoder
  defstruct [:content, status: "pending", errors: []]

  alias Ets.Set

  def init(id) do
    atom_id = String.to_atom(to_string(id))

    case Set.wrap_existing(atom_id) do
      {:ok, set} -> set
      {:error, :table_not_found} -> Set.new!(name: atom_id, protection: :public)
    end
  end

  def clear!(id) do
    id
    |> init()
    |> Set.delete_all!()
  end

  def dump(id) do
    id
    |> init()
    |> Set.to_list!()
    |> Enum.each(fn {index, struct} -> deliver(id, index, struct) end)

    id
  end

  def fetch(id, index) do
    {_, struct} = Set.get!(init(id), index, {index, %__MODULE__{}})
    struct
  end

  def update(id, index, updates \\ %{}) do
    struct =
      id
      |> fetch(index)
      |> Map.merge(updates)

    deliver(id, index, struct)

    Set.put!(init(id), {index, struct})
    id
  end

  defp deliver(id, index, struct) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      %{
        id: Enum.join(Tuple.to_list(index)),
        object: %{content: struct.content, status: struct.status, errors: struct.errors}
      },
      ingest_job_validation_update: id
    )
  end
end
