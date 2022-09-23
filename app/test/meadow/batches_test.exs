defmodule Meadow.BatchesTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Ecto.Adapters.SQL
  alias Meadow.Batches
  alias Meadow.Data.{Indexer, Works}
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo
  alias Meadow.TestSupport.MetadataGenerator

  describe "Meadow.BatchesTest" do
    setup do
      MetadataGenerator.prewarm_cache()

      collection = collection_fixture(%{title: "Original Collection"})

      works = [
        work_fixture(%{
          collection: collection,
          administrative_metadata: %{
            project_desc: ["Existing Value"],
            preservation_level: %{id: "1", scheme: "PRESERVATION_LEVEL"}
          },
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
          administrative_metadata: %{project_desc: ["Existing Value"]},
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
          administrative_metadata: %{project_desc: ["Existing Value"]},
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

      Indexer.reindex_all()
      {:ok, %{works: works}}
    end

    test "process_batch/1 runs and completes a batch update" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      replace = %{
        descriptive_metadata: %{
          title: "All these values",
          alternate_title: ["New Alternate 1", "New Alternate 2"],
          box_number: []
        }
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        replace: Jason.encode!(replace)
      }

      {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)
      assert Batches.list_batches() |> length() == 1
      batch = Batches.get_batch!(batch.id)
      assert batch.status == "complete"
      assert batch.active == false
      assert batch.works_updated == 3
    end

    test "process_batch/1 runs and completes a batch delete" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "delete"
      user = "user123"

      attrs = %{
        query: query,
        type: type,
        user: user
      }

      assert Works.list_works() |> length() == 3

      {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)
      assert Works.list_works() |> length() == 0
      assert Batches.list_batches() |> length() == 1
      batch = Batches.get_batch!(batch.id)
      assert batch.status == "complete"
      assert batch.active == false
      assert batch.works_updated == 3
    end

    test "process_batch/1 does not start a batch if another batch is running" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      replace = %{
        descriptive_metadata: %{
          title: "All these values"
        }
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        replace: Jason.encode!(replace)
      }

      Batches.create_batch(Map.merge(attrs, %{status: "in_progress", active: true}))

      {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)
      assert Batches.list_batches() |> length() == 2
      batch = Batches.get_batch!(batch.id)
      assert batch.status == "queued"
      assert batch.active == false
      assert is_nil(batch.works_updated)
    end

    test "process_batch/1 handles uncontrolled fields" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      add = %{
        descriptive_metadata: %{
          box_name: ["His Airness"],
          date_created: [%{edtf: "1009"}, %{edtf: "100X"}, %{edtf: "~1968"}]
        }
      }

      replace = %{
        descriptive_metadata: %{
          title: "All these values",
          alternate_title: ["New Alternate 1", "New Alternate 2"],
          box_number: []
        }
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        add: Jason.encode!(add),
        replace: Jason.encode!(replace)
      }

      assert {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)

      assert Works.get_works_by_title("All these values") |> length() == 3

      Works.list_works()
      |> Enum.each(fn work ->
        assert work.descriptive_metadata.alternate_title |> length() == 2
        assert work.descriptive_metadata.box_name == ["Michael Jordan", "His Airness"]
        assert work.descriptive_metadata.box_number == []

        assert work.descriptive_metadata.date_created == [
                 %{edtf: "1009", humanized: "1009"},
                 %{edtf: "100X", humanized: "1000s"},
                 %{edtf: "~1968", humanized: "circa 1968?"}
               ]
      end)
    end

    test "process_batch/1 works if field is missing from existing descriptive_metadata map" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      add = %{
        descriptive_metadata: %{
          box_name: ["His Airness"],
          cultural_context: ["Some Context", "Some More Context"],
          date_created: [%{edtf: "1009"}, %{edtf: "100X"}, %{edtf: "~1968"}]
        }
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        add: Jason.encode!(add),
        replace: Jason.encode!(%{})
      }

      assert {:ok, batch} = Batches.create_batch(attrs)

      Repo
      |> SQL.query!(
        "UPDATE works SET descriptive_metadata = descriptive_metadata - 'cultural_context'"
      )

      assert({:ok, _result} = Batches.process_batch(batch))

      Works.list_works()
      |> Enum.each(fn work ->
        assert work.descriptive_metadata.cultural_context == ["Some Context", "Some More Context"]
        assert work.descriptive_metadata.box_name == ["Michael Jordan", "His Airness"]
      end)
    end

    test "process_batch/1 handles controlled fields" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

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

      attrs = %{
        query: query,
        type: type,
        user: user,
        add: Jason.encode!(add),
        delete: Jason.encode!(delete)
      }

      assert {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)

      assert List.first(Works.get_works_by_title("Work 1")).descriptive_metadata.genre
             |> length() == 1

      assert List.first(Works.get_works_by_title("Work 2")).descriptive_metadata.contributor
             |> length() == 1

      assert List.first(Works.get_works_by_title("Work 2")).descriptive_metadata.style_period
             |> length() == 1
    end

    test "process_batch/1 updates collection" do
      new_collection = collection_fixture(%{title: "New Collection"})

      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      replace = %{collection_id: new_collection.id}
      type = "update"
      user = "user123"

      attrs = %{
        query: query,
        type: type,
        user: user,
        replace: Jason.encode!(replace)
      }

      assert Works.list_works(collection_id: new_collection.id) |> length == 0
      assert {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)

      assert Works.list_works(collection_id: new_collection.id) |> length == 3
    end

    test "process_batch/1 handles administrative metadata" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      add = %{
        administrative_metadata: %{
          project_desc: ["A very fun project", "A not so fun project"]
        }
      }

      replace = %{
        administrative_metadata: %{
          status: %{id: "IN PROGRESS", scheme: "STATUS"},
          project_cycle: "The first one"
        }
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        replace: Jason.encode!(replace),
        add: Jason.encode!(add)
      }

      assert Works.list_works() |> length() == 3

      assert {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)

      Works.list_works()
      |> Enum.each(fn work ->
        assert work.administrative_metadata.project_desc |> length() == 3

        assert work.administrative_metadata.status == %{
                 id: "IN PROGRESS",
                 label: "In Progress",
                 scheme: "status"
               }

        assert work.administrative_metadata.project_cycle == "The first one"
      end)
    end

    test "process_batch/1 handles core metadata" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      replace = %{
        visibility: %{id: "OPEN", scheme: "VISIBILITY"}
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        replace: Jason.encode!(replace)
      }

      assert Works.list_works() |> length() == 3

      assert {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)

      Works.list_works()
      |> Enum.each(fn work ->
        assert work.visibility.id == "OPEN"
      end)
    end

    test "process_batch/1 succeeds even if index is out of sync" do
      query = ~s'{"query":{"term":{"workType.id": "IMAGE"}}}'
      type = "update"
      user = "user123"

      from(Work, limit: 1) |> Repo.one() |> Repo.delete()

      replace = %{
        visibility: %{id: "OPEN", scheme: "VISIBILITY"}
      }

      attrs = %{
        query: query,
        type: type,
        user: user,
        replace: Jason.encode!(replace)
      }

      assert Works.list_works() |> length() == 2

      assert {:ok, batch} = Batches.create_batch(attrs)
      assert {:ok, _result} = Batches.process_batch(batch)

      batch = Batches.get_batch!(batch.id)
      assert batch.works_updated == 2

      Works.list_works()
      |> Enum.each(fn work ->
        assert work.visibility.id == "OPEN"
      end)
    end

    test "purge_stalled/1 errors timed out batches stalled in_progress" do
      replace =
        Jason.encode!(%{
          administrative_metadata: %{},
          descriptive_metadata: %{title: ";sdakjf;alsdkjf;aksjdf"}
        })

      attrs = %{
        query: ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
        replace: replace,
        user: "user123",
        type: "update",
        status: "in_progress",
        active: true,
        started: DateTime.add(DateTime.utc_now(), -800, :second)
      }

      {:ok, batch} = Batches.create_batch(attrs)

      assert {:ok, 1} = Batches.purge_stalled(60)

      batch = Batches.get_batch!(batch.id)

      assert batch.status == "error"
      assert batch.works_updated == 0
      assert batch.error == "Batch timed out"
      assert batch.active == false
    end
  end
end
