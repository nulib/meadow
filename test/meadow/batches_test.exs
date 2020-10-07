defmodule Meadow.BatchesTest do
  use Meadow.DataCase
  use Meadow.IndexCase
  alias Meadow.Batches
  alias Meadow.Data.{Indexer, Works}
  alias Meadow.Utils.MetadataGenerator

  describe "Meadow.BatchesTest" do
    setup do
      MetadataGenerator.prewarm_cache()

      collection = collection_fixture(%{title: "Original Collection"})

      works = [
        work_fixture(%{
          collection: collection,
          descriptive_metadata: %{
            title: "Work 1",
            box_name: ["Michael Jordan"],
            box_number: ["23"],
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
          collection: collection,
          descriptive_metadata: %{
            title: "Work 2",
            box_name: ["Michael Jordan"],
            box_number: ["23"],
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
          collection: collection,
          descriptive_metadata: %{
            title: "Work 3",
            box_name: ["Michael Jordan"],
            box_number: ["23"],
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

    test "batch_update/2 handles uncontrolled fields" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'

      add = %{
        descriptive_metadata: %{
          box_name: ["His Airness"]
        }
      }

      replace = %{
        descriptive_metadata: %{
          title: "All these values",
          alternate_title: ["New Alternate 1", "New Alternate 2"],
          box_number: []
        }
      }

      assert {:ok, _result} = Batches.batch_update(query, nil, add, replace)

      assert Works.get_works_by_title("All these values") |> length() == 3

      Works.list_works()
      |> Enum.each(fn work ->
        assert work.descriptive_metadata.alternate_title |> length() == 2
        assert work.descriptive_metadata.box_name == ["Michael Jordan", "His Airness"]
        assert work.descriptive_metadata.box_number == []
      end)
    end

    test "batch_update/2 handles controlled fields" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'

      delete = %{
        contributor: [
          %{
            role: %{scheme: "marc_relator", id: "aut"},
            term: "http://id.loc.gov/authorities/names/n50053919"
          }
        ],
        genre: [
          %{role: nil, term: %{id: "http://vocab.getty.edu/aat/300139140"}}
        ]
      }

      add = %{
        descriptive_metadata: %{
          style_period: [
            %{role: nil, term: "http://vocab.getty.edu/aat/300139140"}
          ]
        }
      }

      assert {:ok, _result} = Batches.batch_update(query, delete, add, nil)

      assert List.first(Works.get_works_by_title("Work 1")).descriptive_metadata.genre
             |> length() == 1

      assert List.first(Works.get_works_by_title("Work 2")).descriptive_metadata.contributor
             |> length() == 1

      assert List.first(Works.get_works_by_title("Work 2")).descriptive_metadata.style_period
             |> length() == 1
    end

    test "batch_update/2 updates collection" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      new_collection = collection_fixture(%{title: "New Collection"})

      assert Works.list_works(collection_id: new_collection.id) |> length == 0

      assert {:ok, _result} =
               Batches.batch_update(query, nil, nil, %{collection_id: new_collection.id})

      assert Works.list_works(collection_id: new_collection.id) |> length == 3
    end
  end
end
