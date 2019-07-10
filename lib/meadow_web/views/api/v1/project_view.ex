defmodule MeadowWeb.Api.V1.ProjectView do
  use MeadowWeb, :view
  alias MeadowWeb.Api.V1.ProjectView

  def render("index.json", %{projects: projects}) do
    %{data: render_many(projects, ProjectView, "project.json")}
  end

  def render("show.json", %{project: project}) do
    %{data: render_one(project, ProjectView, "project.json")}
  end

  def render("project.json", %{project: project}) do
    %{
      id: project.id,
      title: project.title,
      folder: project.folder,
      inserted_at: project.inserted_at,
      updated_at: project.updated_at
    }
  end
end
