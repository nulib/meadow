defmodule MeadowWeb.Resolvers.Ingest do
  @moduledoc """
  Absinthe GraphQL query resolver for Ingest Context

  """
  alias Meadow.Config
  alias Meadow.Ingest.IngestSheets
  alias Meadow.Ingest.{IngestSheets, Projects}
  alias Meadow.Ingest.IngestSheets.IngestSheetValidator
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
        Config.ingest_bucket()
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

  def ingest_sheet(_, %{id: id}, _) do
    {:ok, IngestSheets.get_ingest_sheet!(id)}
  end

  def approve_ingest_sheet(_, %{id: id}, _) do
    id
    |> IngestSheets.get_ingest_sheet!()
    |> approve_ingest_sheet()
  end

  def approve_ingest_sheet(%{status: "valid"} = ingest_sheet) do
    case IngestSheets.update_ingest_sheet_status(ingest_sheet, "approved") do
      {:error, changeset} ->
        {
          :error,
          message: "Could not approve sheet", details: ChangesetErrors.error_details(changeset)
        }

      {:ok, ingest_sheet} ->
        {:ok, ingest_sheet}
    end
  end

  def approve_ingest_sheet(%{status: _}) do
    {
      :error,
      message: "Only valid ingest sheets can be approved"
    }
  end

  def ingest_sheet_progress(_, %{id: id}, _) do
    {:ok, IngestSheets.get_sheet_progress([id]) |> Map.get(id)}
  end

  def ingest_sheet_validations(_, _, _) do
    {:ok, %{validations: [%{id: "sheet", object: %{errors: [], status: "pending"}}]}}
  end

  def validate_ingest_sheet(_, args, _) do
    {response, pid} = args[:ingest_sheet_id] |> IngestSheetValidator.async()
    pid_string = pid |> :erlang.pid_to_list() |> List.to_string()
    {:ok, %{message: to_string(response) <> " : " <> pid_string}}
  end

  def create_ingest_sheet(_, args, _) do
    case IngestSheets.create_ingest_sheet(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create ingest sheet",
         details: ChangesetErrors.error_details(changeset)}

      {:ok, ingest_sheet} ->
        {:ok, ingest_sheet}
    end
  end

  @invalid_delete_status ["approved", "completed"]

  def delete_ingest_sheet(%{status: status}) when status in @invalid_delete_status do
    {
      :error,
      message: "Can't delete ingest sheet with status: " <> status
    }
  end

  def delete_ingest_sheet(%{status: _} = ingest_sheet) do
    case IngestSheets.delete_ingest_sheet(ingest_sheet) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete ingest sheet",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, ingest_sheet} ->
        {:ok, ingest_sheet}
    end
  end

  def delete_ingest_sheet(_, args, _) do
    args[:ingest_sheet_id]
    |> IngestSheets.get_ingest_sheet!()
    |> delete_ingest_sheet()
  end

  def get_presigned_url(_, _, _) do
    url = Bucket.presigned_s3_url(Config.upload_bucket())
    {:ok, %{url: url}}
  end

  def ingest_sheet_rows(_, args, _) do
    {
      :ok,
      args
      |> IngestSheets.list_ingest_sheet_rows()
    }
  end
end
