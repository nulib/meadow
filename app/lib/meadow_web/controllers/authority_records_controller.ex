defmodule MeadowWeb.AuthorityRecordsController do
  use MeadowWeb, :controller
  alias Meadow.Roles
  alias NimbleCSV.RFC4180, as: CSV
  alias NUL.AuthorityRecords
  import Plug.Conn

  require Logger

  plug(:authorize_user)

  def bulk_create(conn, %{"records" => upload}) do
    Logger.info("Received #{upload.filename} of type #{upload.content_type} for bulk import")

    csv_to_maps(upload.path)
    |> do_bulk_create(conn)
  end

  defp do_bulk_create({:error, :bad_format}, conn) do
    case conn |> get_req_header("referer") do
      [referer | _] -> redirect(conn, external: referer)
      _ -> send_resp(conn, 400, "Bad Request")
    end
  end

  defp do_bulk_create({:ok, records}, conn) do
    results =
      records
      |> AuthorityRecords.create_authority_records()
      |> Enum.map(fn {status, %{id: id, label: label, hint: hint}} ->
        [id, label, hint, status]
      end)

    file = "authority_import_#{DateTime.utc_now() |> DateTime.to_unix()}.csv"

    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[attachment; filename="#{file}"])
      |> send_chunked(:ok)

    [~w(id label hint status) | results]
    |> CSV.dump_to_stream()
    |> Stream.each(fn csv_row ->
      chunk(conn, csv_row)
    end)
    |> Stream.run()

    conn
  end

  def bulk_update(conn, %{"records" => upload}) do
    Logger.info("Received #{upload.filename} of type #{upload.content_type} for bulk update")

    csv_to_maps(upload.path)
    |> do_bulk_update(conn)
  end

  defp do_bulk_update({:ok, records}, conn) do
    results =
      records
      |> AuthorityRecords.update_authority_records()
      |> Enum.map(fn
        {:error, %{params: params, errors: errors}} ->
          %{"id" => id, "label" => label, "hint" => hint} = params
          errors = Enum.map(errors, fn {field, {error, _}} -> "<#{field}> #{error}" end)
          [id, label, hint, "error", Enum.join(errors, "; ")]

        {status, %{id: id, label: label, hint: hint}} ->
          [id, label, hint, status]
      end)

    file = "authority_update_#{DateTime.utc_now() |> DateTime.to_unix()}.csv"

    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[attachment; filename="#{file}"])
      |> send_chunked(:ok)

    [~w(id label hint status) | results]
    |> CSV.dump_to_stream()
    |> Enum.reduce_while(conn, fn csv_row, conn ->
      case chunk(conn, csv_row) do
        {:ok, conn} -> {:cont, conn}
        {:error, conn} -> {:halt, conn}
      end
    end)
  end

  defp csv_to_maps(headers, rows) do
    headers = Enum.map(headers, &String.to_atom/1)
    {:ok, Enum.map(rows, fn row -> Enum.zip(headers, row) |> Enum.into(%{}) end)}
  end

  defp csv_to_maps(file) do
    [headers | rows] =
      File.stream!(file, [:trim_bom], :line)
      |> CSV.parse_stream(skip_headers: false)
      |> Enum.to_list()

    case Enum.sort(headers) do
      ~w(hint id label) ->
        csv_to_maps(headers, rows)

      ~w(hint label) ->
        csv_to_maps(headers, rows)

      other ->
        Logger.error("Bad headers: " <> inspect(other))
        {:error, :bad_format}
    end
  rescue
    exception in NimbleCSV.ParseError ->
      Logger.error("Parsing error: " <> inspect(exception))
      {:error, :bad_format}

    exception ->
      reraise exception, __STACKTRACE__
  end

  def export(conn, %{"file" => file} = params) do
    export(conn, Path.extname(file), params)
  end

  defp export(conn, ".csv", %{"file" => file}) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[attachment; filename="#{file}"])
      |> send_chunked(:ok)

    chunk(conn, CSV.dump_to_iodata([~w(id label hint)]))

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
