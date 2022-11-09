defmodule Meadow.Data.WorksTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Config
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Repo

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      descriptive_metadata: %{title: "Test"},
      work_type: %{
        id: "IMAGE",
        scheme: "work_type"
      }
    }
    @invalid_attrs %{accession_number: nil}

    test "list_works/0 returns all works" do
      work_fixture()
      assert length(Works.list_works()) == 1
    end

    test "get_works_by_title/1 fetches the works by title" do
      work = work_fixture()
      title = work.descriptive_metadata.title
      assert length(Works.get_works_by_title(title)) == 1
    end

    test "create_work/1 with valid data creates a work" do
      assert {:ok, %Work{} = _work} = Works.create_work(@valid_attrs)
    end

    test "create_work/1 with invalid data does not create a work" do
      assert {:error, %Ecto.Changeset{}} = Works.create_work(@invalid_attrs)
    end

    test "create_work!/1 with valid data creates a work" do
      assert %Work{} = Works.create_work!(@valid_attrs)
    end

    test "create_work!/1 with invalid data does not create a work" do
      assert_raise(Ecto.InvalidChangesetError, fn -> Works.create_work!(@invalid_attrs) end)
    end

    test "create_work/1 creates a work with an ark" do
      with {:ok, work} <- Works.create_work(@valid_attrs) do
        assert work.descriptive_metadata.ark |> String.match?(~r'^ark:/12345/nu2\d{8}$')
      end
    end

    test "create_work!/1 creates a work with an ark" do
      with work <- Works.create_work!(@valid_attrs) do
        assert work.descriptive_metadata.ark |> String.match?(~r'^ark:/12345/nu2\d{8}$')
      end
    end

    test "update_work/2 updates a work" do
      work = work_fixture()

      assert {:ok, %Work{} = work} =
               Works.update_work(work, %{descriptive_metadata: %{title: "New name"}})

      assert work.descriptive_metadata.title == "New name"
    end

    test "update_work/2 with invalid attributes returns an error" do
      work = work_fixture()
      assert {:error, %Ecto.Changeset{}} = Works.update_work(work, %{published: "Dictionary"})
    end

    test "delete_work/1 deletes a work" do
      work = work_fixture()
      assert {:ok, %Work{} = _work} = Works.delete_work(work)
      assert Enum.empty?(Works.list_works())
    end

    test "get_work!/1 returns a work by id" do
      work = work_fixture()
      assert %Work{} = Works.get_work!(work.id)
    end

    test "accession_exists?/1 returns true if accession is already taken" do
      work = work_fixture()

      assert Works.accession_exists?(work.accession_number) == true
    end

    test "add_to_collection/2 adds the work to a collection" do
      work = work_fixture()

      collection_id =
        collection_fixture()
        |> Map.get(:id)

      assert {:ok, %Work{collection_id: ^collection_id}} =
               Works.add_to_collection(work, collection_id)
    end

    test "add_to_collection/2 with an invalid collection fails" do
      work = work_fixture()

      collection_id = "1234"

      assert {:error, _} = Works.add_to_collection(work, collection_id)
    end

    test "work metadata should default to empty maps" do
      {:ok, work} =
        Works.create_work(%{
          accession_number: "abc",
          work_type: %{
            id: "IMAGE",
            scheme: "work_type"
          }
        })

      assert work.descriptive_metadata.title == nil
    end
  end

  describe "representative images for image type works" do
    setup do
      work =
        work_with_file_sets_fixture(3, %{work_type: %{id: "IMAGE", scheme: "work_type"}}, %{
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          derivatives: %{"pyramid_tiff" => "s3://fo/ob/ar/1-pyramid.tif"}
        })

      file_set = work.file_sets |> Enum.at(1)

      {:ok, %Work{} = work} = Works.set_representative_image(work, file_set)

      {:ok,
       work: work,
       image_id: file_set.id,
       image_url: Meadow.Config.iiif_server_url() <> file_set.id}
    end

    test "placeholder representative image assigned", %{work: work} do
      {:ok, work} = Works.set_representative_image(work, nil)

      assert(Works.get_work!(work.id) |> Map.get(:representative_image)) =~
        "00000000-0000-0000-0000-000000000001"
    end

    test "list_works/0", %{image_url: image_url} do
      [work] = Works.list_works()
      assert(work.representative_image == image_url)
    end

    test "get_work!/1", %{work: work, image_url: image_url} do
      assert(
        Works.get_work!(work.id)
        |> Map.get(:representative_image) == image_url
      )
    end

    test "get_work_by_accession_number!/1", %{work: work, image_url: image_url} do
      assert(
        Works.get_work_by_accession_number!(work.accession_number)
        |> Map.get(:representative_image) == image_url
      )
    end

    test "get_works_by_title/1", %{work: work, image_url: image_url} do
      with title <- work.descriptive_metadata.title do
        [work] = Works.get_works_by_title(title)
        assert(work.representative_image == image_url)
      end
    end

    test "add_representative_image/1 single work", %{work: work, image_url: image_url} do
      work =
        Work
        |> Repo.get!(work.id)
        |> Works.add_representative_image()

      assert work.representative_image == image_url
    end

    test "add_representative_image/1 list of works", %{image_url: image_url} do
      [work] =
        Work
        |> Repo.all()
        |> Works.add_representative_image()

      assert work.representative_image == image_url
    end

    test "add_representative_image/1 stream of works", %{image_url: image_url} do
      stream =
        Work
        |> Repo.stream()
        |> Works.add_representative_image()

      {:ok, [work]} = Repo.transaction(fn -> stream |> Enum.into([]) end)
      assert work.representative_image == image_url
    end

    test "add_representative_image/1 passthrough" do
      assert "Not a work" |> Works.add_representative_image() == "Not a work"
    end

    test "deleting a file set resets the representative image to a placeholder", %{
      image_id: image_id,
      image_url: image_url,
      work: work
    } do
      assert(Works.get_work!(work.id) |> Map.get(:representative_image) == image_url)
      FileSets.get_file_set!(image_id) |> FileSets.delete_file_set()

      assert(Works.get_work!(work.id) |> Map.get(:representative_image)) =~
        "00000000-0000-0000-0000-000000000001"
    end

    test "set_representative_image/2 with a preservation file sets a placeholder representative image" do
      work = work_with_file_sets_fixture(1, %{}, %{role: %{id: "P", scheme: "FILE_SET_ROLE"}})
      file_set = work.file_sets |> Enum.at(1)

      {:ok, %Work{} = work} = Works.set_representative_image(work, file_set)

      assert(Works.get_work!(work.id) |> Map.get(:representative_image)) =~
        "00000000-0000-0000-0000-000000000001"
    end
  end

  describe "representative images for video type works" do
    test "representative image for video works defaults to nil" do
      work =
        work_with_file_sets_fixture(3, %{work_type: %{id: "VIDEO", scheme: "work_type"}}, %{
          role: %{id: "A", scheme: "FILE_SET_ROLE"}
        })

      work = Work |> Repo.get!(work.id) |> Works.add_representative_image()

      assert(Works.get_work!(work.id) |> Map.get(:representative_image)) =~
        "00000000-0000-0000-0000-000000000002"
    end

    test "set_representative_image/1 for video works sets the representative image to the poster url" do
      work =
        work_with_file_sets_fixture(3, %{work_type: %{id: "VIDEO", scheme: "work_type"}}, %{
          role: %{id: "A", scheme: "FILE_SET_ROLE"}
        })

      file_set = work.file_sets |> Enum.at(1)
      derivatives = FileSets.add_derivative(file_set, :poster, FileSets.poster_uri_for(file_set))
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: derivatives})

      {:ok, %Work{} = work} = Works.set_representative_image(work, file_set)

      assert work.representative_image == FileSets.representative_image_url_for(file_set)
    end

    test "add_representative_image/1 single work for video type work" do
      work =
        work_with_file_sets_fixture(3, %{work_type: %{id: "VIDEO", scheme: "work_type"}}, %{
          role: %{id: "A", scheme: "FILE_SET_ROLE"}
        })

      file_set = work.file_sets |> Enum.at(1)
      derivatives = FileSets.add_derivative(file_set, :poster, FileSets.poster_uri_for(file_set))
      {:ok, file_set} = FileSets.update_file_set(file_set, %{derivatives: derivatives})

      {:ok, %Work{} = work} = Works.set_representative_image(work, file_set)

      work =
        Work
        |> Repo.get!(work.id)
        |> Works.add_representative_image()

      assert work.representative_image == FileSets.representative_image_url_for(file_set)
    end
  end

  describe "works with coded term fields" do
    test "create_work/1 with valid coded term fields creates a work" do
      attrs = %{
        accession_number: "12345",
        administrative_metadata: %{
          preservation_level: %{
            id: "1",
            scheme: "preservation_level"
          }
        },
        descriptive_metadata: %{
          title: "Test",
          rights_statement: %{
            id: "http://rightsstatements.org/vocab/NoC-US/1.0/",
            scheme: "rights_statement"
          }
        },
        visibility: %{
          id: "OPEN",
          scheme: "visibility"
        },
        work_type: %{
          id: "IMAGE",
          scheme: "work_type"
        }
      }

      assert {:ok, %Work{} = work} = Works.create_work(attrs)
      assert work.visibility.id == "OPEN"
      assert work.visibility.label == "Public"
      assert work.visibility.scheme == "visibility"

      with administrative_metadata <- work.administrative_metadata do
        assert administrative_metadata.preservation_level.id == "1"
        assert administrative_metadata.preservation_level.label == "Level 1"
        assert administrative_metadata.preservation_level.scheme == "preservation_level"
      end

      with descriptive_metadata <- work.descriptive_metadata do
        assert descriptive_metadata.rights_statement.id ==
                 "http://rightsstatements.org/vocab/NoC-US/1.0/"

        assert descriptive_metadata.rights_statement.label == "No Copyright - United States"
        assert descriptive_metadata.rights_statement.scheme == "rights_statement"
      end
    end

    test "update_work/2 with valid coded term fields updates a work" do
      attrs = %{
        accession_number: "12345",
        visibility: %{
          id: "OPEN",
          scheme: "visibility"
        },
        work_type: %{
          id: "IMAGE",
          scheme: "work_type"
        }
      }

      assert {:ok, %Work{} = work} = Works.create_work(attrs)

      assert {:ok, %Work{} = work} =
               Works.update_work(work, %{
                 visibility: %{
                   id: "RESTRICTED",
                   scheme: "visibility"
                 }
               })

      assert work.visibility.label == "Private"
    end
  end

  describe "works with controlled fields" do
    @valid %{
      accession_number: "12345",
      descriptive_metadata: %{title: "Test"},
      work_type: %{
        id: "IMAGE",
        scheme: "work_type"
      }
    }

    test "create_work/1 with valid controlled entries creates a work" do
      attrs =
        Map.put(@valid, :descriptive_metadata, %{
          contributor: [%{term: "mock1:result1", role: %{id: "aut", scheme: "marc_relator"}}],
          subject: [%{term: "mock1:result2", role: %{id: "TOPICAL", scheme: "subject_role"}}],
          genre: [%{term: "mock2:result3"}]
        })

      assert {:ok, %Work{} = work} = Works.create_work(attrs)

      with descriptive_metadata <- work.descriptive_metadata do
        assert length(descriptive_metadata.contributor) == 1
        assert length(descriptive_metadata.subject) == 1
        assert length(descriptive_metadata.genre) == 1

        with value <- List.first(descriptive_metadata.contributor) do
          assert value.term.label == "First Result"
          assert value.role.label == "Author"
        end

        with value <- List.first(descriptive_metadata.subject) do
          assert value.term.label == "Second Result"
          assert value.role.label == "Topical"
        end

        with value <- List.first(descriptive_metadata.genre) do
          assert value.term.label == "Third Result"
          assert is_nil(value.role)
        end
      end
    end

    test "update_work/2 with valid controlled entries updates a work" do
      attrs =
        Map.put(
          @valid,
          :descriptive_metadata,
          %{
            contributor: [%{term: "mock1:result1", role: %{id: "aut", scheme: "marc_relator"}}],
            subject: [
              %{term: "mock1:result1", role: %{id: "GEOGRAPHICAL", scheme: "subject_role"}},
              %{term: "mock1:result2", role: %{id: "TOPICAL", scheme: "subject_role"}}
            ]
          }
        )

      assert {:ok, %Work{} = work} = Works.create_work(attrs)

      with descriptive_metadata <- work.descriptive_metadata do
        assert length(descriptive_metadata.contributor) == 1
        assert length(descriptive_metadata.subject) == 2
        assert Enum.empty?(descriptive_metadata.genre)
      end

      assert {:ok, %Work{} = work} =
               Works.update_work(work, %{
                 descriptive_metadata: %{
                   genre: [%{term: "mock1:result2"}],
                   subject: [
                     %{term: "mock2:result3", role: %{id: "TOPICAL", scheme: "subject_role"}}
                   ]
                 }
               })

      with descriptive_metadata <- work.descriptive_metadata do
        assert length(descriptive_metadata.contributor) == 1
        assert length(descriptive_metadata.subject) == 1
        assert length(descriptive_metadata.genre) == 1

        with value <- List.first(descriptive_metadata.contributor) do
          assert value.term.label == "First Result"
          assert value.role.label == "Author"
        end

        with value <- List.first(descriptive_metadata.subject) do
          assert value.term.label == "Third Result"
          assert value.role.label == "Topical"
        end

        with value <- List.first(descriptive_metadata.genre) do
          assert value.term.label == "Second Result"
          assert is_nil(value.role)
        end
      end
    end
  end

  describe "works with related url entries" do
    test "create_work/1 with valid related url fields creates a work" do
      attrs = %{
        accession_number: "12345",
        descriptive_metadata: %{
          title: "Test",
          related_url: [
            %{
              url: "http://rightsstatements.org/vocab/NoC-US/1.0/",
              label: %{id: "FINDING_AID", scheme: "related_url"}
            }
          ]
        },
        work_type: %{
          id: "IMAGE",
          scheme: "work_type"
        }
      }

      assert {:ok, %Work{} = work} = Works.create_work(attrs)

      assert length(work.descriptive_metadata.related_url) == 1

      with value <- List.first(work.descriptive_metadata.related_url) do
        assert value.url ==
                 "http://rightsstatements.org/vocab/NoC-US/1.0/"

        assert value.label.label == "Finding Aid"
      end
    end
  end

  describe "reorder file sets" do
    setup do
      work = work_with_file_sets_fixture(5, %{}, %{role: %{id: "A", scheme: "FILE_SET_ROLE"}})
      {:ok, %{work: work, ids: work.file_sets |> Enum.map(& &1.id)}}
    end

    test "update_file_set_order/1 success", %{work: work, ids: ids} do
      with work_id <- work.id do
        assert {:ok,
                %{
                  index_1: %{id: id_1, position: 1},
                  index_2: %{id: id_2, position: 2},
                  index_3: %{id: id_3, position: 3},
                  index_4: %{id: id_4, position: 4},
                  index_5: %{id: id_5, position: 5},
                  work: %Work{id: ^work_id}
                }} = Works.update_file_set_order(work_id, "A", Enum.reverse(ids))

        assert [id_5, id_4, id_3, id_2, id_1] == ids
      end
    end

    test "update_file_set_order/1 errors on missing id", %{work: work, ids: [missing_id | ids]} do
      assert {:error, error_text} = Works.update_file_set_order(work.id, "A", ids)
      assert String.contains?(error_text, missing_id)
      assert String.match?(error_text, ~r/missing \[.+\]/)
    end

    test "update_file_set_order/1 errors on extra id", %{work: work, ids: ids} do
      with extra_id <- Ecto.UUID.generate() do
        assert {:error, error_text} = Works.update_file_set_order(work.id, "A", [extra_id | ids])
        assert String.contains?(error_text, extra_id)
        assert String.match?(error_text, ~r/^Extra/)
      end
    end
  end

  describe "verify_file_sets/1" do
    @bucket Config.preservation_bucket()
    @key "verification_test/path/to/file.tif"
    @content "test/fixtures/coffee.tif"
    @fixture %{
      bucket: @bucket,
      key: @key,
      content: File.read!(@content)
    }
    setup do
      work = work_with_file_sets_fixture(3)
      location = "s3://#{Config.preservation_bucket()}/#{@key}"

      Enum.each(work.file_sets, fn file_set ->
        FileSets.update_file_set(file_set, %{
          core_metadata: %{location: location}
        })
      end)

      {:ok, %{work: work}}
    end

    @tag s3: [@fixture]
    test "verify_file_sets/1 verifies file sets are present in preservation location", %{
      work: work
    } do
      Enum.each(Works.verify_file_sets(work.id), fn result ->
        assert result.verified == true
      end)
    end

    test "verify_file_sets/1 verifies file sets are not present in preservation location" do
      work = work_with_file_sets_fixture(3)

      Enum.each(Works.verify_file_sets(work.id), fn result ->
        assert result.verified == false
      end)
    end
  end

  describe "mint_ark/1" do
    setup %{work_type: work_type} do
      {:ok, work: work_fixture(%{work_type: %{id: work_type, scheme: "work_type"}})}
    end

    seed_values("coded_terms/work_type")
    |> Enum.each(fn %{id: work_type} ->
      @tag work_type: work_type
      test "mint_ark/1 mints an ark for #{work_type} work type", %{work: work} do
        assert {:ok, %{descriptive_metadata: %{ark: ark}}} = Works.mint_ark(work)
        assert is_binary(ark)
      end

      @tag work_type: work_type
      test "mint_ark!/1 mints an ark for #{work_type} work type", %{work: work} do
        assert Works.mint_ark!(work)
      end
    end)
  end
end
