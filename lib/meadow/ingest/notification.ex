defmodule Meadow.Notification do
  @moduledoc """
  Handles Phoenix channel notifications, synchronized with ETS.
  """

  @derive Jason.Encoder
  defstruct [:content, status: "pending", errors: []]

  alias Ets.Set
  alias Phoenix.Channel.Server, as: Channel

  def init(id) do
    atom_id = String.to_atom(to_string(id))

    case Set.wrap_existing(atom_id) do
      {:ok, set} -> set
      {:error, :table_not_found} -> Set.new!(name: atom_id, protection: :public)
    end
  end

  def dump(id) do
    Set.to_list!(init(id))
    |> Enum.each(fn {index, struct} -> deliver(id, index, struct) end)
  end

  def fetch(id, index) do
    {_, struct} = Set.get!(init(id), index, {index, %__MODULE__{}})
    struct
  end

  def update(id, index, updates \\ %{}) do
    struct =
      fetch(id, index)
      |> Map.merge(updates)

    deliver(id, index, struct)

    case Set.put(init(id), {index, struct}) do
      {:ok, _set} -> {:ok, struct}
      other -> other
    end
  end

  defp deliver(id, index, struct) do
    Channel.broadcast!(Meadow.PubSub, to_string(id), "update", %{
      id: Tuple.to_list(index),
      object: struct
    })

    :timer.sleep(50)
  end
end
