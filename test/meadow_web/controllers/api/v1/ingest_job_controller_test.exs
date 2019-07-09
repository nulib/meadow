defmodule MeadowWeb.IngestJobControllerTest do
  use MeadowWeb.ConnCase

  alias Meadow.Ingest
  alias Meadow.Ingest.IngestJob

  @create_attrs %{
    name: "some name",
    presigned_url: "some presigned_url"
  }
  @update_attrs %{
    name: "some updated name",
    presigned_url: "some updated presigned_url"
  }
  @invalid_attrs %{name: nil, presigned_url: nil}

  def project_fixture() do
    {:ok, project} = Ingest.create_project(%{title: "Some project name"})
    project
  end

  def fixture(:ingest_job) do
    project = project_fixture()
    {:ok, ingest_job} = Ingest.create_ingest_job(Map.put(@create_attrs, :project_id, project.id))
    ingest_job
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all ingest_jobs", %{conn: conn} do
      conn = get(conn, Routes.v1_ingest_job_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create ingest_job" do
    test "renders ingest_job when data is valid", %{conn: conn} do
      project = project_fixture()

      conn =
        post(conn, Routes.v1_ingest_job_path(conn, :create),
          ingest_job: Map.put(@create_attrs, :project_id, project.id)
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.v1_ingest_job_path(conn, :show, id))

      assert %{
               "id" => id,
               "name" => "some name",
               "presigned_url" => "some presigned_url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.v1_ingest_job_path(conn, :create), ingest_job: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update ingest_job" do
    setup [:create_ingest_job]

    test "renders ingest_job when data is valid", %{
      conn: conn,
      ingest_job: %IngestJob{id: id} = ingest_job
    } do
      conn =
        put(conn, Routes.v1_ingest_job_path(conn, :update, ingest_job),
          ingest_job: Map.put(@update_attrs, :project_id, ingest_job.project_id)
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.v1_ingest_job_path(conn, :show, id))

      assert %{
               "id" => id,
               "name" => "some updated name",
               "presigned_url" => "some updated presigned_url"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, ingest_job: ingest_job} do
      conn =
        put(conn, Routes.v1_ingest_job_path(conn, :update, ingest_job), ingest_job: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete ingest_job" do
    setup [:create_ingest_job]

    test "deletes chosen ingest_job", %{conn: conn, ingest_job: ingest_job} do
      conn = delete(conn, Routes.v1_ingest_job_path(conn, :delete, ingest_job))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.v1_ingest_job_path(conn, :show, ingest_job))
      end
    end
  end

  defp create_ingest_job(_) do
    ingest_job = fixture(:ingest_job)
    {:ok, ingest_job: ingest_job}
  end
end
