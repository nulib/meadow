defmodule MeadowWeb.Resolvers.Data.CSV.MetadataUpdateJobs do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Data.CSV.MetadataUpdateJobs

  def list_jobs(_, _args, _) do
    {:ok, MetadataUpdateJobs.list_jobs() |> serialize_job_errors()}
  end

  def get_job(_, %{id: id}, _) do
    {:ok, MetadataUpdateJobs.get_job(id) |> serialize_job_errors()}
  end

  def update(_, %{filename: filename, source: source}, %{context: %{current_user: user}}) do
    case MetadataUpdateJobs.create_job(%{filename: filename, source: source, user: user.username}) do
      {:ok, job} -> {:ok, job}
      {:error, errors} -> {:error, message: "Could not create job", details: errors}
    end
  end

  defp serialize_job_errors([]), do: []

  defp serialize_job_errors([job | jobs]),
    do: [serialize_job_errors(job) | serialize_job_errors(jobs)]

  defp serialize_job_errors(job), do: Map.put(job, :errors, serialize_errors(job.errors))

  defp serialize_errors(nil), do: nil

  defp serialize_errors({field, value}) when is_list(value), do: %{field: field, messages: value}
  defp serialize_errors({field, value}), do: %{field: field, messages: [value]}

  defp serialize_errors(errors) do
    errors
    |> Enum.map(fn
      %{"row" => row, "errors" => errors} ->
        %{row: row, errors: Enum.map(errors, &serialize_errors/1)}

      %{row: row, errors: errors} ->
        %{row: row, errors: Enum.map(errors, &serialize_errors/1)}
    end)
  end
end
