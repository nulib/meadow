defmodule MeadowWeb.Resolvers.Ingest do
  alias Meadow.Ingest
  alias Meadow.Ingest.Bucket
  alias MeadowWeb.Schema.ChangesetErrors

  def projects(_, args, _) do
    {:ok, Ingest.list_projects(args)}
  end

  def project(_, %{id: id}, _) do
    {:ok, Ingest.get_project!(id)}
  end

  def create_project(_, args, _) do
    case Ingest.create_project(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create project", details: ChangesetErrors.error_details(changeset)}

      {:ok, project} ->
        {:ok, project}
    end
  end

  def delete_project(_, args, _) do
    project = Ingest.get_project!(args[:project_id])

    case Ingest.delete_project(project) do
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
    {:ok, Ingest.get_ingest_job!(id)}
  end

  def create_ingest_job(_, args, _) do
    case Ingest.create_ingest_job(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create ingest job", details: ChangesetErrors.error_details(changeset)}

      {:ok, ingest_job} ->
        {:ok, ingest_job}
    end
  end

  def delete_ingest_job(_, args, _) do
    ingest_job = Ingest.get_ingest_job!(args[:ingest_job_id])

    case Ingest.delete_ingest_job(ingest_job) do
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

  def change_ingest_job_state(_, args, _) do
    ingest_job = Ingest.get_ingest_job!(args[:ingest_job_id])

    case Ingest.change_ingest_job_state(ingest_job, args[:state]) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not update ingest job state",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, ingest_job} ->
        publish_ingest_job_change(ingest_job)
        {:ok, ingest_job}
    end
  end

  defp publish_ingest_job_change(ingest_job) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      ingest_job,
      ingest_job_change: ingest_job.id
    )
  end
end
