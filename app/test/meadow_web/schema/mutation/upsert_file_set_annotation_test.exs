defmodule MeadowWeb.Schema.Mutation.UpsertFileSetAnnotationTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.Data.FileSets

  load_gql(MeadowWeb.Schema, "test/gql/UpsertFileSetAnnotation.gql")

  setup do
    {:ok, file_set: file_set_fixture()}
  end

  test "creates a nav_place annotation", %{file_set: file_set} do
    content =
      Jason.encode!(%{
        type: "FeatureCollection",
        features: [
          %{
            type: "Feature",
            properties: %{label: "Chicago"},
            geometry: %{type: "Point", coordinates: [-87.65005, 41.85003]}
          }
        ]
      })

    assert {:ok, query_data} =
             query_gql(
               variables: %{
                 "fileSetId" => file_set.id,
                 "type" => "nav_place",
                 "content" => content
               },
               context: gql_context()
             )

    annotation = get_in(query_data, [:data, "upsertFileSetAnnotation"])
    assert annotation["fileSetId"] == file_set.id
    assert annotation["type"] == "nav_place"
    assert annotation["status"] == "completed"
    assert annotation["content"] == content
  end

  test "creates a nav_place annotation with supported GeoJSON geometries", %{file_set: file_set} do
    content =
      Jason.encode!(%{
        type: "FeatureCollection",
        features: [
          %{
            type: "Feature",
            properties: %{label: %{en: ["Point place"]}},
            geometry: %{type: "Point", coordinates: [-87.65005, 41.85003]}
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Stops"]}},
            geometry: %{
              type: "MultiPoint",
              coordinates: [[-87.65, 41.85], [-87.64, 41.86]]
            }
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Route"]}},
            geometry: %{
              type: "LineString",
              coordinates: [[-87.65, 41.85], [-87.64, 41.86]]
            }
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Routes"]}},
            geometry: %{
              type: "MultiLineString",
              coordinates: [
                [[-87.65, 41.85], [-87.64, 41.86]],
                [[-87.63, 41.87], [-87.62, 41.88]]
              ]
            }
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Search area"]}},
            geometry: %{
              type: "Polygon",
              coordinates: [[[-87.7, 41.8], [-87.6, 41.8], [-87.6, 41.9], [-87.7, 41.8]]]
            }
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Search areas"]}},
            geometry: %{
              type: "MultiPolygon",
              coordinates: [
                [[[-87.7, 41.8], [-87.6, 41.8], [-87.6, 41.9], [-87.7, 41.8]]]
              ]
            }
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Unlocated place"]}},
            geometry: nil
          },
          %{
            type: "Feature",
            properties: %{label: %{en: ["Compound place"]}},
            geometry: %{
              type: "GeometryCollection",
              geometries: [
                %{type: "Point", coordinates: [-87.65, 41.85]},
                %{type: "LineString", coordinates: [[-87.65, 41.85], [-87.64, 41.86]]}
              ]
            }
          }
        ]
      })

    assert {:ok, query_data} =
             query_gql(
               variables: %{
                 "fileSetId" => file_set.id,
                 "type" => "nav_place",
                 "content" => content
               },
               context: gql_context()
             )

    annotation = get_in(query_data, [:data, "upsertFileSetAnnotation"])
    assert annotation["type"] == "nav_place"
    assert annotation["content"] == content
  end

  test "updates an existing annotation for the same file set and type", %{file_set: file_set} do
    original =
      Jason.encode!(%{
        type: "FeatureCollection",
        features: [
          %{
            type: "Feature",
            properties: %{label: "Chicago"},
            geometry: %{type: "Point", coordinates: [-87.65005, 41.85003]}
          }
        ]
      })

    updated =
      Jason.encode!(%{
        type: "FeatureCollection",
        features: [
          %{
            type: "Feature",
            properties: %{label: "Evanston"},
            geometry: %{type: "Point", coordinates: [-87.6877, 42.0451]}
          }
        ]
      })

    {:ok, existing} = FileSets.upsert_annotation_content(file_set.id, "nav_place", original)

    assert {:ok, query_data} =
             query_gql(
               variables: %{
                 "fileSetId" => file_set.id,
                 "type" => "nav_place",
                 "content" => updated,
                 "language" => ["en"]
               },
               context: gql_context()
             )

    annotation = get_in(query_data, [:data, "upsertFileSetAnnotation"])
    assert annotation["id"] == existing.id
    assert annotation["content"] == updated
    assert annotation["language"] == ["en"]
    assert length(FileSets.list_annotations(file_set)) == 1
  end

  test "creates a georeference annotation", %{file_set: file_set} do
    content =
      Jason.encode!(%{
        "@context" => [
          "http://iiif.io/api/extension/georef/1/context.json",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        id: "urn:test:georeference",
        type: "Annotation",
        motivation: "georeferencing",
        target: %{
          type: "SpecificResource",
          source: %{id: "https://example.test/canvas/1", type: "Canvas"}
        },
        body: %{
          type: "FeatureCollection",
          features: [
            %{
              type: "Feature",
              properties: %{resourceCoords: [10, 20]},
              geometry: %{type: "Point", coordinates: [-87.65, 41.85]}
            }
          ]
        }
      })

    assert {:ok, query_data} =
             query_gql(
               variables: %{
                 "fileSetId" => file_set.id,
                 "type" => "georeference",
                 "content" => content
               },
               context: gql_context()
             )

    annotation = get_in(query_data, [:data, "upsertFileSetAnnotation"])
    assert annotation["type"] == "georeference"
    assert annotation["status"] == "completed"
  end

  test "returns an error for invalid nav_place content", %{file_set: file_set} do
    assert {:ok, query_data} =
             query_gql(
               variables: %{
                 "fileSetId" => file_set.id,
                 "type" => "nav_place",
                 "content" => Jason.encode!(%{type: "FeatureCollection", features: []})
               },
               context: gql_context()
             )

    assert [%{message: "Invalid annotation content"}] = query_data[:errors]
  end

  test "returns an error for invalid georeference content", %{file_set: file_set} do
    assert {:ok, query_data} =
             query_gql(
               variables: %{
                 "fileSetId" => file_set.id,
                 "type" => "georeference",
                 "content" => Jason.encode!(%{type: "Annotation"})
               },
               context: gql_context()
             )

    assert [%{message: "Invalid annotation content"}] = query_data[:errors]
  end
end
