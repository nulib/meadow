defmodule Ecto.Jason do
  def encode(value) do
    value
    |> prepare()
    |> Jason.encode()
  end

  def encode!(value) do
    value
    |> prepare()
    |> Jason.encode!()
  end

  defp prepare(struct) when is_struct(struct, DateTime), do: struct
  defp prepare(struct) when is_struct(struct, NaiveDateTime), do: struct

  defp prepare(value) when is_list(value), do: value |> Enum.map(&prepare/1)

  defp prepare(value) when is_struct(value), do: value |> Map.from_struct() |> prepare()

  defp prepare(value) when is_map(value) do
    value
    |> Enum.map(fn {key, value} -> {key, prepare(value)} end)
    |> Enum.reject(fn {key, value} ->
      cond do
        key |> to_string() |> String.starts_with?("__") -> true
        value |> is_struct(Ecto.Association.NotLoaded) -> true
        true -> false
      end
    end)
    |> Enum.into(%{})
  end

  defp prepare(other), do: other
end
