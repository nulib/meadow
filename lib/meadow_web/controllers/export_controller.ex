defmodule MeadowWeb.ExportController do
  use MeadowWeb, :controller
  alias Meadow.Data.CSV.Export
  alias Meadow.Roles
  import Plug.Conn

  plug :authorize_user

  def export(conn, %{"file" => file} = params) do
    export(conn, Path.extname(file), params)
  end

  defp export(conn, ".csv", %{"file" => file, "query" => query}) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header(
        "content-disposition",
        ~s[attachment; filename="#{file}"]
      )
      |> send_chunked(:ok)

    for chunk <- Export.stream_csv(query) do
      chunk(conn, chunk)
    end

    conn
  end

  defp export(conn, _, _) do
    conn
    |> put_resp_content_type("text/plain")
    |> resp(404, "Not Found")
    |> halt()
  end

  def authorize_user(%{assigns: %{current_user: current_user}} = conn, _params) do
    if Roles.authorized?(current_user, :any) do
      conn
    else
      conn
      |> put_resp_content_type("text/plain")
      |> resp(403, "Unauthorized")
      |> halt()
    end
  end
end
