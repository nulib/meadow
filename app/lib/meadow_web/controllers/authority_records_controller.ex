defmodule MeadowWeb.AuthorityRecordsController do
  use MeadowWeb, :controller
  alias Meadow.Roles
  alias NimbleCSV.RFC4180, as: CSV
  alias NUL.AuthorityRecords
  import Plug.Conn

  plug(:authorize_user)

  def export(conn, %{"file" => file} = params) do
    export(conn, Path.extname(file), params)
  end

  defp export(conn, ".csv", %{"file" => file}) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[attachment; filename="#{file}"])
      |> send_chunked(:ok)

    AuthorityRecords.with_stream(fn stream ->
      stream
      |> Stream.map(fn result -> [[result.id, result.label, result.hint]] end)
      |> Stream.map(&CSV.dump_to_iodata/1)
      |> Stream.each(fn csv_row ->
        chunk(conn, csv_row)
      end)
      |> Stream.run()
    end)

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
