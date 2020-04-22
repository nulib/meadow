defmodule Meadow.Data.IndexTimes do
  @moduledoc """
  The IndexTimes context.
  """

  alias Meadow.Data.Schemas.IndexTime
  alias Meadow.Repo

  require Logger

  def reset_all! do
    Repo.delete_all(IndexTime)
  end
end
