defmodule Meadow.Data.DonutWorks do
  @moduledoc """
  The DonutWorks context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.DonutWork
  alias Meadow.Repo

  def get_donut_work(id) do
    DonutWork
    |> Repo.get(id)
  end

  def get_donut_work!(id) do
    DonutWork
    |> Repo.get!(id)
  end

  def list_donut_works do
    DonutWork
    |> Repo.all()
  end

  def create_donut_work(attrs) do
    %DonutWork{}
    |> DonutWork.changeset(attrs)
    |> Repo.insert()
  end

  def create_donut_work!(attrs) do
    %DonutWork{}
    |> DonutWork.changeset(attrs)
    |> Repo.insert!()
  end

  def with_next_donut_work(func) do
    Repo.transaction(
      fn ->
        from(dw in DonutWork,
          where: dw.status == "pending",
          order_by: [asc: :inserted_at],
          limit: 1,
          lock: "FOR UPDATE SKIP LOCKED"
        )
        |> Repo.one()
        |> func.()
      end,
      timeout: 60_000
    )
  end

  def update_donut_work(%DonutWork{} = donut_work, attrs) do
    donut_work
    |> DonutWork.changeset(attrs)
    |> Repo.update()
  end

  def update_donut_work!(%DonutWork{} = donut_work, attrs) do
    donut_work
    |> DonutWork.changeset(attrs)
    |> Repo.update!()
  end

  def delete_donut_work(%DonutWork{} = donut_work) do
    Repo.delete(donut_work)
  end

  def reset! do
    Repo.delete_all(DonutWork)
  end
end
