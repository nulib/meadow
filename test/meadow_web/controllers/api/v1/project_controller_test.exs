defmodule MeadowWeb.ProjectControllerTest do
  use MeadowWeb.ConnCase

  alias Meadow.Ingest
  alias Meadow.Ingest.Project

  @create_attrs %{
    title: "some title"
  }
  @update_attrs %{
    title: "some updated title"
  }
  @invalid_attrs %{title: nil}

  def fixture(:project) do
    {:ok, project} = Ingest.create_project(@create_attrs)
    project
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all projects", %{conn: conn} do
      conn = get(conn, Routes.v1_project_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create project" do
    test "renders project when data is valid", %{conn: conn} do
      conn = post(conn, Routes.v1_project_path(conn, :create), project: @create_attrs)
      assert %{"id" => id, "folder" => folder} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.v1_project_path(conn, :show, id))

      assert %{
               "id" => id,
               "folder" => folder,
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.v1_project_path(conn, :create), project: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update project" do
    setup [:create_project]

    test "renders project when data is valid", %{
      conn: conn,
      project: %Project{id: id, folder: folder} = project
    } do
      conn = put(conn, Routes.v1_project_path(conn, :update, project), project: @update_attrs)
      assert %{"id" => ^id, "folder" => ^folder} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.v1_project_path(conn, :show, id))

      assert %{
               "id" => id,
               "folder" => folder,
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, project: project} do
      conn = put(conn, Routes.v1_project_path(conn, :update, project), project: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete project" do
    setup [:create_project]

    test "deletes chosen project", %{conn: conn, project: project} do
      conn = delete(conn, Routes.v1_project_path(conn, :delete, project))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.v1_project_path(conn, :show, project))
      end
    end
  end

  defp create_project(_) do
    project = fixture(:project)
    {:ok, project: project}
  end
end
