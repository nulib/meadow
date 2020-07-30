defmodule Meadow.BatchesTest do
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Meadow.Batches
  alias Meadow.Data.{Indexer, Works}
  alias Meadow.Utils.MetadataGenerator

  describe "Meadow.BatchesTest" do
    setup do
      MetadataGenerator.prewarm_cache()

      works = [
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
        }),
        work_fixture(%{
          descriptive_metadata: %{
            title: "Work 2",
            contributor: [
              %{
                role: %{scheme: "marc_relator", id: "aut"},
                term: %{id: "http://id.loc.gov/authorities/names/n50053919"}
              },
              %{
                role: %{scheme: "marc_relator", id: "col"},
                term: %{id: "http://id.loc.gov/authorities/names/n50053919"}
              }
            ],
            genre: [
              %{role: nil, term: %{id: "http://vocab.getty.edu/aat/300139140"}}
            ]
          }
        }),
        work_fixture(%{
          descriptive_metadata: %{
            title: "Work 3",
            contributor: [
              %{
                role: %{scheme: "marc_relator", id: "aut"},
                term: %{id: "http://id.loc.gov/authorities/names/n50053919"}
              },
              %{
                role: %{scheme: "marc_relator", id: "aut"},
                term: %{id: "http://id.loc.gov/authorities/names/n78030997"}
              }
            ],
            genre: [
              %{role: nil, term: %{id: "http://vocab.getty.edu/aat/300139140"}}
            ]
          }
        })
      ]

      Indexer.reindex_all!()
      {:ok, %{works: works}}
    end

    test "batch_update/2" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'

      delete = %{
        contributor: [
          %{
            role: %{scheme: "marc_relator", id: "aut"},
            term: %{id: "http://id.loc.gov/authorities/names/n50053919"}
          }
        ],
        genre: [
          %{role: nil, term: %{id: "http://vocab.getty.edu/aat/300139140"}}
        ]
      }

      assert {:ok, _result} = Batches.batch_update(query, delete)

      assert List.first(Works.get_works_by_title("Work 1")).descriptive_metadata.genre
             |> length() == 1

      assert List.first(Works.get_works_by_title("Work 2")).descriptive_metadata.contributor
             |> length() == 1
    end
  end
end
