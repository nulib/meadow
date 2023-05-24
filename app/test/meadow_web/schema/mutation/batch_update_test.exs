defmodule MeadowWeb.Schema.Mutation.BatchUpdateTest do
  use Meadow.DataCase
  use Meadow.IndexCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase
  alias Meadow.Data.Indexer

  load_gql(MeadowWeb.Schema, "test/gql/BatchUpdate.gql")

  setup do
    prewarm_controlled_term_cache()

    work_fixture(%{
      descriptive_metadata: %{
        title: "Work 1",
        contributor: [
          %{
            role: %{scheme: "marc_relator", id: "aut"},
            term: %{id: "http://id.loc.gov/authorities/names/n50053919"}
          }
        ],
        genre: [
          %{role: nil, term: %{id: "http://vocab.getty.edu/aat/300386217"}},
          %{role: nil, term: %{id: "http://vocab.getty.edu/aat/300139140"}}
        ]
      }
    })

    Indexer.reindex_all()
    :ok
  end

  test "should be a valid mutation" do
    result =
      query_gql(
        variables: %{
          "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
          "delete" => %{
            "contributor" => [
              %{
                "role" => %{"scheme" => "MARC_RELATOR", "id" => "aut"},
                "term" => "http://id.loc.gov/authorities/names/n50053919"
              }
            ],
            "genre" => [
              %{"term" => "http://vocab.getty.edu/aat/300139140"}
            ]
          },
          "add" => %{
            "descriptive_metadata" => %{
              "contributor" => [
                %{
                  "role" => %{"scheme" => "MARC_RELATOR", "id" => "pbl"},
                  "term" => "http://id.loc.gov/authorities/names/n50053919"
                }
              ]
            }
          }
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "batchUpdate", "status"])
    assert response =~ "QUEUED"
  end

  test "adds only should be a valid mutation" do
    result =
      query_gql(
        variables: %{
          "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
          "add" => %{
            "descriptive_metadata" => %{
              "contributor" => [
                %{
                  "role" => %{"scheme" => "MARC_RELATOR", "id" => "pbl"},
                  "term" => "http://id.loc.gov/authorities/names/n50053919"
                }
              ]
            }
          }
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    response = get_in(query_data, [:data, "batchUpdate", "status"])
    assert response =~ "QUEUED"
  end

  test "no updates should not be a valid mutation" do
    result =
      query_gql(
        variables: %{
          "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
        },
        context: gql_context()
      )

    assert {:ok, query_data} = result

    error = List.first(get_in(query_data, [:errors]))
    assert error.message == "No updates specified"
  end

  describe "authorization" do
    test "users are not authorized to update via batch" do
      {:ok, result} =
        query_gql(
          variables: %{
            "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
            "add" => %{
              "descriptive_metadata" => %{
                "contributor" => [
                  %{
                    "role" => %{"scheme" => "MARC_RELATOR", "id" => "pbl"},
                    "term" => "http://id.loc.gov/authorities/names/n50053919"
                  }
                ]
              }
            }
          },
          context: %{current_user: %{username: "abc123", role: "User"}}
        )

      assert %{errors: [%{message: "Forbidden", status: 403}]} = result
    end

    test "editors and above are authorized to update via batch" do
      {:ok, result} =
        query_gql(
          variables: %{
            "query" => ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
            "add" => %{
              "descriptive_metadata" => %{
                "contributor" => [
                  %{
                    "role" => %{"scheme" => "MARC_RELATOR", "id" => "pbl"},
                    "term" => "http://id.loc.gov/authorities/names/n50053919"
                  }
                ]
              }
            }
          },
          context: %{current_user: %{username: "abc123", role: "Editor"}}
        )

      assert result.data["batchUpdate"]
    end
  end
end
