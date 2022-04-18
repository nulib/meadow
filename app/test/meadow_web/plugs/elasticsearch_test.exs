defmodule ElasticsearchTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Meadow.IndexCase

  alias Elasticsearch.API.AWS
  alias Meadow.Data.Indexer

  @total_hits_path ~w(hits total value)

  describe "MeadowWeb.Plugs.Elasticsearch" do
    test "only accepts methods: [POST, GET, OPTIONS, HEAD]" do
      %{works: [work | _]} = indexable_data()
      Indexer.synchronize_index()

      conn =
        build_conn()
        |> auth_user(user_fixture())
        |> delete("/elasticsearch/#{@meadow_index}/_doc/#{work.id}")

      assert conn.status == 400
    end

    test "returns results for _search reqeusts" do
      conn =
        build_conn()
        |> auth_user(user_fixture())
        |> put_req_header("content-type", "application/json")
        |> post(
          "/elasticsearch/#{@meadow_index}/_search",
          Jason.encode!(%{"query" => %{"match_all" => %{}}})
        )

      assert Jason.decode!(conn.resp_body)["hits"]["total"]["value"] == indexed_doc_count()
    end

    test "returns results for _msearch reqeusts" do
      %{works: [work | _]} = indexable_data()
      Indexer.synchronize_index()

      mquery =
        "{\"preference\":\"q\"}\n{\"query\":{\"bool\":{\"must\":[{\"bool\":{\"must\":{\"bool\":{\"should\":[{\"multi_match\":{\"query\":\"p\",\"fields\":[\"title\"],\"type\":\"best_fields\",\"operator\":\"or\",\"fuzziness\":0}},{\"multi_match\":{\"query\":\"#{work.descriptive_metadata.title}\",\"fields\":[\"title\"],\"type\":\"phrase_prefix\",\"operator\":\"or\"}}],\"minimum_should_match\":\"1\"}}}}]}},\"size\":10}\n"

      conn =
        build_conn()
        |> auth_user(user_fixture())
        |> put_req_header("content-type", "application/x-ndjson")
        |> post("/elasticsearch/#{@meadow_index}/_msearch", mquery)

      assert Jason.decode!(conn.resp_body) |> get_in(@total_hits_path) > 1
    end

    test "returns results for query string requests" do
      %{works: [work | _]} = indexable_data()
      Indexer.synchronize_index()

      conn =
        build_conn()
        |> auth_user(user_fixture())
        |> put_req_header("content-type", "application/json")
        |> get("/elasticsearch/#{@meadow_index}/_search?q=#{work.descriptive_metadata.title}")

      assert Jason.decode!(conn.resp_body) |> get_in(@total_hits_path) > 0
    end

    test "sign AWS request" do
      assert AWS.build_signed_request(
               "https://localhost:8080/",
               [access_key: "fake", secret: "fake"],
               nil
             )
    end
  end
end
