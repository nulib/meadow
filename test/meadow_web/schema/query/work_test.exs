defmodule MeadowWeb.Schema.Query.WorkTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  @query """
  query($id: ID!) {
    work(id: $id) {
      id
    }
  }
  """

  test "work query returns the work with a given id" do
    work = work_fixture()
    variables = %{"id" => work.id}

    conn = build_conn() |> auth_user(user_fixture())
    conn = get conn, "/api/graphql", query: @query, variables: variables

    assert %{
             "data" => %{
               "work" => %{"id" => work.id}
             }
           } == json_response(conn, 200)
  end

  @accession_query """
  query($accession_number: String!) {
    workByAccession(accessionNumber: $accession_number) {
      id
    }
  }
  """

  test "workByAccession query returns the work with a given accession_number" do
    work = work_fixture()
    variables = %{"accession_number" => work.accession_number}

    conn = build_conn() |> auth_user(user_fixture())
    conn = get conn, "/api/graphql", query: @accession_query, variables: variables

    assert %{
             "data" => %{
               "workByAccession" => %{"id" => work.id}
             }
           } == json_response(conn, 200)
  end
end
