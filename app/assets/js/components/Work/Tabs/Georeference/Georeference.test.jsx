import React from "react";
import { fireEvent, screen, waitFor } from "@testing-library/react";

import {
  AUTHORITIES_SEARCH,
  GEONAMES_PLACE,
} from "@js/components/Work/controlledVocabulary.gql";
import { GET_WORK } from "@js/components/Work/work.gql";
import {
  DELETE_FILE_SET_ANNOTATION,
  UPSERT_FILE_SET_ANNOTATION,
} from "./georeference.gql";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { mockWork } from "@js/components/Work/work.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

let mockMapClickIndex = 0;
const mockMapCoordinates = [
  [-87.65, 41.85],
  [-87.64, 41.86],
  [-87.63, 41.85],
  [-87.62, 41.84],
];

useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

jest.mock("./ImageCoordinatePicker", () => ({
  __esModule: true,
  default: ({ onDimensions, onPointSelected }) => (
    <div data-testid="mock-image-picker">
      <button
        type="button"
        onClick={() => {
          onDimensions({ width: 1000, height: 800 });
          onPointSelected([100, 200]);
        }}
      >
        Pick image point
      </button>
    </div>
  ),
}));

jest.mock("./LeafletMap", () => ({
  __esModule: true,
  default: ({
    fitToData,
    geoJson,
    markers = [],
    onMapPointSelected,
    previewAnnotation,
    useCrosshairCursor,
  }) => (
    <div
      data-testid="mock-leaflet-map"
      data-crosshair-cursor={useCrosshairCursor ? "true" : "false"}
      data-has-preview={previewAnnotation ? "true" : "false"}
    >
      {fitToData && <span>fit-to-data</span>}
      {geoJson?.features?.map((feature, index) => (
        <span key={`${feature.geometry?.type}-${index}`}>
          GeoJSON: {feature.geometry?.type}
        </span>
      ))}
      {markers.map((marker) => (
        <span key={`${marker.label}-${marker.latitude}-${marker.longitude}`}>
          {marker.label}: {marker.latitude}, {marker.longitude}
        </span>
      ))}
      <button
        type="button"
        onClick={() => {
          const coordinates =
            mockMapCoordinates[mockMapClickIndex % mockMapCoordinates.length];
          mockMapClickIndex += 1;
          onMapPointSelected(coordinates);
        }}
      >
        Pick map point
      </button>
    </div>
  ),
}));

const { default: WorkTabsGeoreference } = await import("./Georeference");

const imageFileSet = {
  ...mockWork.fileSets[0],
  annotations: [],
  extractedMetadata: JSON.stringify({
    exif: {
      value: {
        imageWidth: 7337,
        imageHeight: 9833,
      },
    },
  }),
  representativeImageUrl: "https://iiif.example.test/iiif/3/file-set-1",
  coreMetadata: {
    ...mockWork.fileSets[0].coreMetadata,
    mimeType: "image/tiff",
  },
};

const work = {
  ...mockWork,
  fileSets: [imageFileSet],
  manifestUrl: "https://api.example.test/works/ABC123?as=iiif",
  representativeImage: `https://iiif.example.test/iiif/3/${imageFileSet.id}`,
};

const annotatedWork = {
  ...work,
  fileSets: [
    {
      ...imageFileSet,
      annotations: [
        {
          id: "georeference-annotation",
          fileSetId: imageFileSet.id,
          type: "georeference",
          language: ["en"],
          content: JSON.stringify({
            body: {
              features: [
                {
                  type: "Feature",
                  properties: {
                    resourceCoords: [100, 200],
                  },
                  geometry: {
                    type: "Point",
                    coordinates: [-87.65, 41.85],
                  },
                },
              ],
            },
          }),
        },
        {
          id: "nav-place-annotation",
          fileSetId: imageFileSet.id,
          type: "nav_place",
          language: ["en"],
          content: JSON.stringify({
            type: "FeatureCollection",
            features: [
              {
                id: "place-1",
                type: "Feature",
                properties: {
                  label: { en: ["Chicago"] },
                  summary: { en: ["Illinois"] },
                },
                geometry: {
                  type: "Point",
                  coordinates: [-87.65, 41.85],
                },
              },
            ],
          }),
        },
      ],
    },
  ],
};

function upsertMock(type, validateVariables = () => true) {
  return {
    request: {
      query: UPSERT_FILE_SET_ANNOTATION,
    },
    variableMatcher: (variables) =>
      variables.fileSetId === imageFileSet.id &&
      variables.type === type &&
      typeof variables.content === "string" &&
      variables.language?.[0] === "en" &&
      validateVariables(variables),
    result: {
      data: {
        upsertFileSetAnnotation: {
          id: `${type}-annotation`,
          fileSetId: imageFileSet.id,
          type,
          language: ["en"],
          status: "completed",
          content: "{}",
          insertedAt: "2026-05-19T00:00:00Z",
          updatedAt: "2026-05-19T00:00:00Z",
        },
      },
    },
  };
}

function deleteMock(annotationId = "georeference-annotation") {
  return {
    request: {
      query: DELETE_FILE_SET_ANNOTATION,
      variables: { annotationId },
    },
    result: {
      data: {
        deleteFileSetAnnotation: {
          id: annotationId,
          fileSetId: imageFileSet.id,
        },
      },
    },
  };
}

const refetchWorkMock = {
  request: {
    query: GET_WORK,
    variables: { id: work.id },
  },
  result: {
    data: { work },
  },
};

const geoNamesSearchMock = {
  request: {
    query: AUTHORITIES_SEARCH,
    variables: { authority: "geonames", query: "chicago" },
  },
  result: {
    data: {
      authoritiesSearch: [
        {
          id: "geonames:4887398",
          label: "Chicago",
          hint: "Illinois, United States",
        },
      ],
    },
  },
};

const geoNamesPlaceMock = {
  request: {
    query: GEONAMES_PLACE,
    variables: { id: "geonames:4887398" },
  },
  result: {
    data: {
      geonamesPlace: {
        id: "geonames:4887398",
        type: "Feature",
        properties: {
          label: { en: ["Chicago"] },
          summary: { en: ["Illinois, United States"] },
        },
        geometry: {
          type: "Point",
          coordinates: [-87.65005, 41.85003],
        },
        bbox: [-87.94011, 41.64454, -87.52414, 42.02304],
      },
    },
  },
};

describe("WorkTabsGeoreference", () => {
  beforeEach(() => {
    mockMapClickIndex = 0;
  });

  it("renders an empty state when a work has no file sets", async () => {
    renderWithRouterApollo(
      <WorkTabsGeoreference isActive work={{ ...work, fileSets: [] }} />,
    );

    expect(
      await screen.findByText(
        /No file sets are available for geographic annotation/i,
      ),
    ).toBeInTheDocument();
  });

  it("disables warping for a selected non-image file set", async () => {
    renderWithRouterApollo(
      <WorkTabsGeoreference
        isActive
        work={{
          ...work,
          fileSets: [
            {
              ...imageFileSet,
              representativeImageUrl: null,
              coreMetadata: {
                ...imageFileSet.coreMetadata,
                mimeType: "text/plain",
              },
            },
          ],
        }}
      />,
    );

    expect(
      await screen.findByText(
        /Georeferencing requires a selected image file set/i,
      ),
    ).toBeInTheDocument();
  });

  it("saves a nav_place annotation from a map click", async () => {
    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />, {
      mocks: [upsertMock("nav_place"), refetchWorkMock],
    });

    fireEvent.click(await screen.findByText("Location"));
    fireEvent.click(await screen.findByText("Pick map point"));
    fireEvent.click(await screen.findByText("Save Location"));

    await waitFor(() => {
      expect(screen.getByDisplayValue("Map location 1")).toBeInTheDocument();
    });
  });

  it("appends multiple location map click markers", async () => {
    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />);

    fireEvent.click(await screen.findByText("Location"));
    fireEvent.click(await screen.findByText("Pick map point"));
    fireEvent.click(await screen.findByText("Pick map point"));

    expect(screen.getByDisplayValue("Map location 1")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Map location 2")).toBeInTheDocument();
    expect(screen.getByText("fit-to-data")).toBeInTheDocument();
  });

  it("saves nav_place labels and summaries as language maps", async () => {
    const validateNavPlaceContent = jest.fn((variables) => {
      const content = JSON.parse(variables.content);
      expect(content.features[0].properties.label).toEqual({
        en: ["Chicago lakefront"],
      });
      expect(content.features[0].properties.summary).toEqual({
        en: ["Edited summary"],
      });
      expect(content.features[0].id).toBeUndefined();
      return true;
    });

    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />, {
      mocks: [
        upsertMock("nav_place", validateNavPlaceContent),
        refetchWorkMock,
      ],
    });

    fireEvent.click(await screen.findByText("Location"));
    fireEvent.click(await screen.findByText("Pick map point"));
    fireEvent.change(screen.getByDisplayValue("Map location 1"), {
      target: { value: "Chicago lakefront" },
    });
    fireEvent.change(screen.getByLabelText("Summary for Chicago lakefront"), {
      target: { value: "Edited summary" },
    });
    fireEvent.click(await screen.findByText("Save Location"));

    await waitFor(() => {
      expect(validateNavPlaceContent).toHaveBeenCalled();
    });
  });

  it("zooms to a GeoNames result before explicitly adding it as a point", async () => {
    const validateGeoNamesPointContent = jest.fn((variables) => {
      const content = JSON.parse(variables.content);
      expect(content.features[0].id).toEqual(
        "https://sws.geonames.org/4887398/",
      );
      expect(content.features[0].properties.sourceId).toEqual(
        "https://sws.geonames.org/4887398/",
      );
      return true;
    });

    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />, {
      mocks: [
        geoNamesSearchMock,
        geoNamesPlaceMock,
        upsertMock("nav_place", validateGeoNamesPointContent),
        refetchWorkMock,
      ],
    });

    fireEvent.click(await screen.findByText("Location"));
    fireEvent.change(screen.getByLabelText("GeoNames place"), {
      target: { value: "chicago" },
    });
    fireEvent.click(screen.getByText("Search"));

    fireEvent.click(await screen.findByText("Chicago"));

    expect(await screen.findByText("Add Point")).toBeInTheDocument();
    expect(screen.getByText("Add Bounds")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: Polygon")).toBeInTheDocument();
    expect(screen.queryByDisplayValue("Chicago")).not.toBeInTheDocument();
    expect(
      screen.getByText("Chicago: 41.85003, -87.65005"),
    ).toBeInTheDocument();
    expect(screen.getByText("fit-to-data")).toBeInTheDocument();

    fireEvent.click(screen.getByText("Add Point"));

    expect(screen.getByDisplayValue("Chicago")).toBeInTheDocument();
    expect(screen.queryByText("Add Point")).not.toBeInTheDocument();
    expect(
      screen.queryByText(/Illinois, United States/),
    ).not.toBeInTheDocument();

    fireEvent.click(screen.getByText("Save Location"));

    await waitFor(() => {
      expect(validateGeoNamesPointContent).toHaveBeenCalled();
    });
  });

  it("adds a GeoNames bounding box as a polygon when available", async () => {
    const validateGeoNamesBoundsContent = jest.fn((variables) => {
      const content = JSON.parse(variables.content);
      expect(content.features[0].id).toEqual(
        "https://sws.geonames.org/4887398/#bbox",
      );
      expect(content.features[0].properties.sourceId).toEqual(
        "https://sws.geonames.org/4887398/",
      );
      expect(content.features[0].properties.bbox).toEqual([
        -87.94011, 41.64454, -87.52414, 42.02304,
      ]);
      expect(content.features[0].properties.sourceGeometry).toEqual("bbox");
      expect(content.features[0].geometry.type).toEqual("Polygon");
      return true;
    });

    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />, {
      mocks: [
        geoNamesSearchMock,
        geoNamesPlaceMock,
        upsertMock("nav_place", validateGeoNamesBoundsContent),
        refetchWorkMock,
      ],
    });

    fireEvent.click(await screen.findByText("Location"));
    fireEvent.change(screen.getByLabelText("GeoNames place"), {
      target: { value: "chicago" },
    });
    fireEvent.click(screen.getByText("Search"));
    fireEvent.click(await screen.findByText("Chicago"));
    fireEvent.click(await screen.findByText("Add Bounds"));

    expect(screen.getByDisplayValue("Chicago bounds")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: Polygon")).toBeInTheDocument();
    expect(screen.queryByText("Add Bounds")).not.toBeInTheDocument();

    fireEvent.click(screen.getByText("Save Location"));

    await waitFor(() => {
      expect(validateGeoNamesBoundsContent).toHaveBeenCalled();
    });
  });

  it("saves a georeference annotation after three GCP pairs", async () => {
    const validateGeoreferenceContent = jest.fn((variables) => {
      const content = JSON.parse(variables.content);
      expect(content.target.source.width).toEqual(7337);
      expect(content.target.source.height).toEqual(9833);
      expect(content.target.selector.value).toEqual(
        '<svg width="7337" height="9833"><polygon points="0,0 7337,0 7337,9833 0,9833" /></svg>',
      );
      return true;
    });

    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />, {
      mocks: [
        upsertMock("georeference", validateGeoreferenceContent),
        refetchWorkMock,
      ],
    });

    expect(screen.getByTestId("mock-leaflet-map")).toHaveAttribute(
      "data-crosshair-cursor",
      "true",
    );

    for (let index = 0; index < 3; index += 1) {
      fireEvent.click(await screen.findByText("Pick image point"));
      fireEvent.click(await screen.findByText("Pick map point"));
    }

    fireEvent.click(await screen.findByText("Save Georeference"));

    await waitFor(() => {
      expect(validateGeoreferenceContent).toHaveBeenCalled();
      expect(screen.getByText("3")).toBeInTheDocument();
    });
  });

  it("toggles the rectified image map preview after enough control points", async () => {
    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />);

    const previewToggle = await screen.findByLabelText(
      "Preview rectified image on map",
    );
    expect(previewToggle).toBeDisabled();
    expect(screen.getByTestId("mock-leaflet-map")).toHaveAttribute(
      "data-has-preview",
      "false",
    );

    for (let index = 0; index < 3; index += 1) {
      fireEvent.click(screen.getByText("Pick image point"));
      fireEvent.click(screen.getByText("Pick map point"));
    }

    expect(previewToggle).toBeEnabled();
    expect(screen.getByTestId("mock-leaflet-map")).toHaveAttribute(
      "data-has-preview",
      "true",
    );

    fireEvent.click(previewToggle);

    expect(screen.getByTestId("mock-leaflet-map")).toHaveAttribute(
      "data-has-preview",
      "false",
    );
  });

  it("deletes a whole georeference annotation instead of requiring point-by-point removal", async () => {
    renderWithRouterApollo(
      <WorkTabsGeoreference isActive work={annotatedWork} />,
      {
        mocks: [deleteMock(), refetchWorkMock],
      },
    );

    expect(await screen.findByText("Control points")).toBeInTheDocument();
    fireEvent.click(screen.getByText("Delete Control Points"));

    await waitFor(() => {
      expect(screen.getByText("No control points added.")).toBeInTheDocument();
    });
  });

  it("draws a polygon directly from map clicks in Location mode", async () => {
    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />);

    fireEvent.click(await screen.findByText("Location"));
    expect(screen.getByTestId("mock-leaflet-map")).toHaveAttribute(
      "data-crosshair-cursor",
      "true",
    );
    fireEvent.change(screen.getByLabelText("Geometry"), {
      target: { value: "Polygon" },
    });
    fireEvent.click(await screen.findByText("Pick map point"));
    expect(screen.queryByText("fit-to-data")).not.toBeInTheDocument();
    fireEvent.click(await screen.findByText("Pick map point"));
    fireEvent.click(await screen.findByText("Pick map point"));
    fireEvent.click(screen.getByText("Add Geometry"));

    expect(screen.getByDisplayValue("Polygon 1")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: Polygon")).toBeInTheDocument();
  });

  it("loads supported GeoJSON geometry types into Location mode", async () => {
    renderWithRouterApollo(<WorkTabsGeoreference isActive work={work} />);

    const geometryFeatures = [
      {
        type: "Feature",
        properties: { label: { en: ["Point place"] } },
        geometry: { type: "Point", coordinates: [-87.65, 41.85] },
      },
      {
        type: "Feature",
        properties: { label: { en: ["Route"] } },
        geometry: {
          type: "LineString",
          coordinates: [
            [-87.65, 41.85],
            [-87.64, 41.86],
          ],
        },
      },
      {
        type: "Feature",
        properties: { label: { en: ["Stops"] } },
        geometry: {
          type: "MultiPoint",
          coordinates: [
            [-87.65, 41.85],
            [-87.64, 41.86],
          ],
        },
      },
      {
        type: "Feature",
        properties: { label: { en: ["Area"] } },
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-87.7, 41.8],
              [-87.6, 41.8],
              [-87.6, 41.9],
              [-87.7, 41.9],
              [-87.7, 41.8],
            ],
          ],
        },
      },
      {
        type: "Feature",
        properties: { label: { en: ["Routes"] } },
        geometry: {
          type: "MultiLineString",
          coordinates: [
            [
              [-87.65, 41.85],
              [-87.64, 41.86],
            ],
            [
              [-87.63, 41.87],
              [-87.62, 41.88],
            ],
          ],
        },
      },
      {
        type: "Feature",
        properties: { label: { en: ["Areas"] } },
        geometry: {
          type: "MultiPolygon",
          coordinates: [
            [
              [
                [-87.7, 41.8],
                [-87.6, 41.8],
                [-87.6, 41.9],
                [-87.7, 41.9],
                [-87.7, 41.8],
              ],
            ],
          ],
        },
      },
      {
        type: "Feature",
        properties: { label: { en: ["Compound"] } },
        geometry: {
          type: "GeometryCollection",
          geometries: [
            { type: "Point", coordinates: [-87.65, 41.85] },
            {
              type: "LineString",
              coordinates: [
                [-87.65, 41.85],
                [-87.64, 41.86],
              ],
            },
          ],
        },
      },
    ];

    fireEvent.click(await screen.findByText("Location"));
    fireEvent.click(screen.getByText("Paste GeoJSON"));
    fireEvent.change(screen.getByLabelText("GeoJSON"), {
      target: {
        value: JSON.stringify({
          type: "FeatureCollection",
          features: geometryFeatures,
        }),
      },
    });
    fireEvent.click(screen.getByText("Replace with GeoJSON"));

    expect(screen.getByDisplayValue("Point place")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Route")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Stops")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Area")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Routes")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Areas")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Compound")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: LineString")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: MultiPoint")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: Polygon")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: MultiLineString")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: MultiPolygon")).toBeInTheDocument();
    expect(screen.getByText("GeoJSON: GeometryCollection")).toBeInTheDocument();
  });

  it("shows existing annotations on the map and in the data tables", async () => {
    renderWithRouterApollo(
      <WorkTabsGeoreference isActive work={annotatedWork} />,
    );

    expect(await screen.findByText("Control points")).toBeInTheDocument();
    expect(screen.getByText("100, 200")).toBeInTheDocument();
    expect(screen.getByText("-87.65, 41.85")).toBeInTheDocument();
    expect(screen.getByText(/GCP 1: 41.85, -87.65/i)).toBeInTheDocument();
    expect(
      screen.queryByText(/Existing location annotation/i),
    ).not.toBeInTheDocument();

    fireEvent.click(screen.getByText("Location"));

    expect(await screen.findByText("Coordinates")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Chicago")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Illinois")).toBeInTheDocument();
    expect(screen.getByDisplayValue("41.85")).toBeInTheDocument();
    expect(screen.getByDisplayValue("-87.65")).toBeInTheDocument();
  });
});
