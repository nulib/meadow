defmodule Meadow.Ingest do
  @moduledoc """
  The PrimaryIngest context. Functions for dealing with Ingest, Sheets and Projects
  """

  import Ecto.Query, warn: false
  alias Meadow.Repo

  # Dataloader

  def datasource do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _) do
    queryable
  end
end
