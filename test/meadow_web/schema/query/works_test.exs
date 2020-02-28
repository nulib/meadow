defmodule MeadowWeb.Schema.Query.WorksTest do
  use MeadowWeb.ConnCase, async: true
  alias Meadow.Data.Works

  @query """
  query {
    works{
      id
    }
  }
  """

  test "works query returns all works" do
    work_fixture()
    work_fixture()
    work_fixture()

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query)

    assert %{
             "data" => %{
               "works" => [
                 %{"id" => _},
                 %{"id" => _},
                 %{"id" => _}
               ]
             }
           } = json_response(response, 200)
  end

  @query """
  query($limit: Int!) {
    works(limit: $limit){
      id
    }
  }
  """
  @variables %{"limit" => 2}
  test "works query limits the number of works returned" do
    work_fixture()
    work_fixture()
    work_fixture()

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "works" => [
                 %{"id" => _},
                 %{"id" => _}
               ]
             }
           } = json_response(response, 200)
  end

  @match_attrs %{
    accession_number: "12345",
    visibility: "open",
    work_type: "image",
    descriptive_metadata: %{title: "This Title"}
  }
  @no_match_attrs %{
    accession_number: "123456",
    visibility: "restricted",
    work_type: "video",
    descriptive_metadata: %{title: "Other One"}
  }

  @query """
  query ($filter: WorkFilter!) {
    works(filter: $filter) {
      descriptiveMetadata{
        title
      }
    }
  }
  """
  @variables %{"filter" => %{"matching" => "This Title"}}
  test "works query returns works filtered by title" do
    work_fixture(@match_attrs)
    work_fixture(@no_match_attrs)

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "works" => [
                 %{"descriptiveMetadata" => %{"title" => "This Title"}}
               ]
             }
           } == json_response(response, 200)
  end

  @variables %{"filter" => %{"workType" => "IMAGE"}}
  test "works query returns works filtered by workType" do
    work_fixture(@match_attrs)
    work_fixture(@no_match_attrs)

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "works" => [
                 %{"descriptiveMetadata" => %{"title" => "This Title"}}
               ]
             }
           } == json_response(response, 200)
  end

  @variables %{"filter" => %{"visibility" => "OPEN"}}
  test "works query returns works filtered by visibility" do
    work_fixture(@match_attrs)
    work_fixture(@no_match_attrs)

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "works" => [
                 %{"descriptiveMetadata" => %{"title" => "This Title"}}
               ]
             }
           } == json_response(response, 200)
  end

  @query """
  query {
    works{
      id
      representativeImage
    }
  }
  """
  test "works query returns work with representative image" do
    work = work_fixture()
    %{id: image_id} = file_set_fixture(%{work_id: work.id})
    work |> Works.update_work(%{representative_file_set_id: image_id})

    conn = build_conn() |> auth_user(user_fixture())

    response = get(conn, "/api/graphql", query: @query)
    expected = "#{Meadow.Config.iiif_server_url()}#{image_id}"

    assert %{
             "data" => %{
               "works" => [
                 %{
                   "id" => _,
                   "representativeImage" => ^expected
                 }
               ]
             }
           } = json_response(response, 200)
  end
end
