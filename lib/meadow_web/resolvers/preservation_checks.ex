defmodule MeadowWeb.Resolvers.Data.PreservationChecks do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Data.PreservationChecks

  def preservation_checks(_, _args, _) do
    {:ok, PreservationChecks.list_jobs()}
  end
end
