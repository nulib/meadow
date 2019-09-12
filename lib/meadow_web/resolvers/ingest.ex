defmodule MeadowWeb.Resolvers.Ingest do
  @moduledoc """
  Absinthe GraphQL query resolver for Ingest Context

  """
  alias Meadow.Ingest.{IngestJobs, Projects}
  alias Meadow.Ingest.IngestJobs.InventoryValidator
  alias Meadow.Ingest.Projects.Bucket
  alias MeadowWeb.Schema.ChangesetErrors

  def projects(_, args, _) do
    {:ok, Projects.list_projects(args)}
  end

  def project(_, %{id: id}, _) do
    {:ok, Projects.get_project!(id)}
  end

  def create_project(_, args, _) do
    case Projects.create_project(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create project", details: ChangesetErrors.error_details(changeset)}

      {:ok, project} ->
        Application.get_env(:meadow, :ingest_bucket)
        |> Bucket.create_project_folder(project.folder)

        {:ok, project}
    end
  end

  def delete_project(_, args, _) do
    project = Projects.get_project!(args[:project_id])

    case Projects.delete_project(project) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete project", details: ChangesetErrors.error_details(changeset)
        }

      {:ok, project} ->
        {:ok, project}
    end
  end

  def ingest_job(_, %{id: id}, _) do
    {:ok, IngestJobs.get_ingest_job!(id)}
  end

  def ingest_job_progress(_, %{id: id}, _) do
    {:ok, Meadow.Ingest.IngestJobs.get_job_progress([id]) |> Map.get(id)}
  end

  def ingest_job_validations(_, _, _) do
    {:ok, %{validations: [%{id: "job", object: %{errors: [], status: "pending"}}]}}
  end

  def validate_ingest_job(_, args, _) do
    {response, pid} = args[:ingest_job_id] |> InventoryValidator.async()
    pid_string = pid |> :erlang.pid_to_list() |> List.to_string()
    {:ok, %{message: to_string(response) <> " : " <> pid_string}}
  end

  def create_ingest_job(_, args, _) do
    case IngestJobs.create_ingest_job(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create ingest job", details: ChangesetErrors.error_details(changeset)}

      {:ok, ingest_job} ->
        {:ok, ingest_job}
    end
  end

  def delete_ingest_job(_, args, _) do
    ingest_job = IngestJobs.get_ingest_job!(args[:ingest_job_id])

    case IngestJobs.delete_ingest_job(ingest_job) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete ingest job",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, ingest_job} ->
        {:ok, ingest_job}
    end
  end

  def get_presigned_url(_, _, _) do
    url = Bucket.presigned_s3_url(Application.get_env(:meadow, :upload_bucket))
    {:ok, %{url: url}}
  end

  def ingest_job_rows(_, args, _) do
    {
      :ok,
      args
      |> IngestJobs.list_ingest_rows()
    }
  end
end
