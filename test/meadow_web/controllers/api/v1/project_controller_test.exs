defmodule MeadowWeb.ProjectControllerTest do
  use MeadowWeb.ConnCase
  use ExUnit.Case

  import Mox
  import OpenApiSpex.Test.Assertions

  alias Meadow.Ingest
  alias Meadow.Ingest.Project
  alias MeadowWeb.Schemas

  @create_attrs %{
    title: "some title"
  }
  @update_attrs %{
    title: "some updated title"
  }
  @invalid_attrs %{title: nil}

  setup do
    %{spec: MeadowWeb.ApiSpec.spec()}
  end

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

    test "ProjectsController produces a `ProjectsResponse`", %{
      conn: conn,
      spec: spec
    } do
      {:ok, _project1} =
        Ingest.create_project(%{
          title: "Project 1"
        })

      {:ok, _project2} =
        Ingest.create_project(%{
          title: "Project 2"
        })

      conn
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> get(Routes.v1_project_path(conn, :index))
      |> json_response(200)
      |> assert_schema("ProjectsResponse", spec)
    end
  end

  describe "create project" do
    test "renders project when data is valid", %{conn: conn} do
      Meadow.ExAwsHttpMock
      |> stub(:request, fn _method, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200}}
      end)

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

    test "ProjectsController.create produces a `ProjectResponse`", %{conn: conn, spec: spec} do
      Meadow.ExAwsHttpMock
      |> stub(:request, fn _method, _url, _body, _headers, _opts ->
        {:ok, %{status_code: 200}}
      end)

      conn
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> post(Routes.v1_project_path(conn, :create), project: @create_attrs)
      |> json_response(201)
      |> assert_schema("ProjectResponse", spec)
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

  test "Project example matches schema", %{spec: spec} do
    assert_schema(Schemas.Project.schema().example, "Project", spec)
  end

  test "ProjectRequest example matches schema", %{spec: spec} do
    assert_schema(Schemas.ProjectRequest.schema().example, "ProjectRequest", spec)
  end

  test "ProjectResponse example matches schema", %{spec: spec} do
    assert_schema(Schemas.ProjectResponse.schema().example, "ProjectResponse", spec)
  end

  test "ProjectsResponse example matches schema", %{spec: spec} do
    assert_schema(Schemas.ProjectsResponse.schema().example, "ProjectsResponse", spec)
  end

  defp create_project(_) do
    project = fixture(:project)
    {:ok, project: project}
  end
end
