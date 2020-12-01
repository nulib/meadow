defmodule Meadow.Data.CSVExportTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias NimbleCSV.RFC4180, as: CSV
  alias Meadow.Data.{CSVExport, Indexer, Works}

  import Assertions

  @query %{query: %{match_all: %{}}}
  @sample_record %{
    abstract: "Abstract",
    accession_number: "Voyager:2588027",
    alternate_title: "That Bruce Campbell Show",
    box_name: "Box 1",
    box_number: "1",
    caption: "Caption",
    catalog_key: "Catalog Key",
    citation: "Citation",
    contributor:
      "pbl:http://id.loc.gov/authorities/names/n83175996 | vac:http://id.loc.gov/authorities/names/n85153068 | lil:http://id.loc.gov/authorities/names/n50053919 | aut:http://id.loc.gov/authorities/names/no2011087251 | mrb:http://id.loc.gov/authorities/names/no2011087251 | stl:http://id.loc.gov/authorities/names/n85153068",
    creator:
      "http://vocab.getty.edu/ulan/500030701 | http://vocab.getty.edu/ulan/500445403 | http://vocab.getty.edu/ulan/500102192 | http://vocab.getty.edu/ulan/500029268",
    date_created: "~1899",
    description: "Description",
    folder_name: "Folder 2",
    folder_number: "2",
    genre: "http://vocab.getty.edu/aat/300185712",
    identifier: "BRISCO",
    keywords: "orb | bly | western",
    language:
      "http://id.loc.gov/vocabulary/languages/bug | http://id.loc.gov/vocabulary/languages/nia | http://id.loc.gov/vocabulary/languages/lin | http://id.loc.gov/vocabulary/languages/cha",
    legacy_identifier: "827 | BCDE.2",
    library_unit: "UNIVERSITY_MAIN_LIBRARY",
    license: "http://www.europeana.eu/portal/rights/rr-r.html",
    location:
      "https://sws.geonames.org/2347283 | https://sws.geonames.org/3530597 | https://sws.geonames.org/3582677",
    notes: "Notes",
    physical_description_material: "DVD",
    physical_description_size: "12cm",
    preservation_level: "2",
    project_cycle: "Redevelopment",
    project_desc: "Description of Project | Another Description of Project",
    project_manager: "Brisco County, Jr.",
    project_name: "The Coming Thing",
    project_proposer: "Socrates Poole | Lord Bowler",
    project_task_number: "1899.827",
    provenance: "Television",
    published: "false",
    publisher: "Boam/Cuse Productions | Warner Bros. Television",
    related_material: "Related Material",
    related_url: "RELATED_INFORMATION:https://www.imdb.com/title/tt0105932/",
    rights_holder: "Rights Holder",
    rights_statement: "http://rightsstatements.org/vocab/InC/1.0/",
    scope_and_contents: "Scope | Contents",
    series: "The Adventures of Brisco County, Jr.",
    source: "Source",
    status: "STARTED",
    style_period:
      "http://vocab.getty.edu/aat/300378903 | http://vocab.getty.edu/aat/300312140 | http://vocab.getty.edu/aat/300375743",
    subject:
      "geo:http://id.loc.gov/authorities/subjects/sh85070610 | top:http://id.loc.gov/authorities/subjects/sh2002006395 | top:http://id.loc.gov/authorities/subjects/sh85076671 | geo:http://id.loc.gov/authorities/subjects/sh85076671 | geo:http://id.loc.gov/authorities/subjects/sh85076710",
    table_of_contents: "Season One | There Is No Season Two",
    technique:
      "http://vocab.getty.edu/aat/300438611 | http://vocab.getty.edu/aat/300400619 | http://vocab.getty.edu/aat/300053376",
    terms_of_use: "Terms of Use",
    title: "Eaque optio est praesentium tenetur impedit autem minima.",
    visibility: "AUTHENTICATED"
  }

  setup do
    collection = collection_fixture()

    with {{work_fixture_data, controlled_term_data}, []} <-
           Code.eval_file("test/fixtures/work_fixtures.exs") do
      Authoritex.Mock.set_data(controlled_term_data)

      work_fixture_data
      |> Enum.each(fn work_data ->
        work_data |> Map.put(:collection_id, collection.id) |> Works.create_work!()
      end)

      Indexer.synchronize_index()
    end

    {:ok, %{collection: collection}}
  end

  test "export_works/0", %{collection: collection} do
    result = CSVExport.generate_csv(@query)
    [query | [csv | []]] = String.split(result, ~r/[\r\n]+/, parts: 2)
    [header | data] = CSV.parse_string(csv, skip_headers: false)
    sample_row = Enum.find(data, &Enum.member?(&1, @sample_record[:accession_number]))
    sample_record = Enum.zip(header, sample_row) |> Enum.into(%{})

    generated_ids = data |> Enum.map(&List.first/1)
    work_ids = Works.list_works() |> Enum.map(&Map.get(&1, :id))
    assert_lists_equal(generated_ids, work_ids)

    assert query =~ "match_all"

    assert Enum.member?(header, "id")
    assert {:ok, _} = Map.get(sample_record, "id") |> Ecto.UUID.dump()

    assert Enum.member?(header, "collection_id")
    assert Map.get(sample_record, "collection_id") == collection.id

    with shoulder <- Meadow.Config.ark_config() |> Map.get(:default_shoulder) do
      assert Enum.member?(header, "ark")
      assert Map.get(sample_record, "ark") |> String.starts_with?(shoulder)
    end

    @sample_record
    |> Enum.each(fn {field, expected_value} ->
      assert Enum.member?(header, to_string(field))
      assert Map.get(sample_record, to_string(field)) == expected_value
    end)
  end
end
