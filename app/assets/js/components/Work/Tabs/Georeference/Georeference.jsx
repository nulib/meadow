import React, { useEffect, useMemo, useState } from "react";
import PropTypes from "prop-types";
import { useLazyQuery, useMutation } from "@apollo/client/react";

import {
  AUTHORITIES_SEARCH,
  GEONAMES_PLACE,
} from "@js/components/Work/controlledVocabulary.gql";
import { Button, Notification } from "@nulib/design-system";
import ImageCoordinatePicker from "./ImageCoordinatePicker";
import LeafletMap from "./LeafletMap";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import {
  DELETE_FILE_SET_ANNOTATION,
  UPSERT_FILE_SET_ANNOTATION,
} from "./georeference.gql";
import { GET_WORK } from "@js/components/Work/work.gql";
import { toastWrapper } from "@js/services/helpers";
import {
  annotationByType,
  buildGeoreferenceAnnotation,
  buildNavPlaceFeatureCollection,
  controlPointsFromGeoreferenceAnnotation,
  GEOJSON_GEOMETRY_TYPES,
  getDefaultFileSet,
  getFileSetImageDimensions,
  getImageServiceUrl,
  getFileSetLabel,
  isImageFileSet,
  parseNavPlaceGeoJson,
  placesFromNavPlaceAnnotation,
} from "./helpers";

const defaultMapCenter = {
  latitude: 41.85003,
  longitude: -87.65005,
  zoom: 4,
};

const GEOMETRY_COLLECTION_PART_TYPES = ["Point", "LineString", "Polygon"];

function getCenterFromCoordinates(coordinates, zoom) {
  const validCoordinates = coordinates.filter(
    ([longitude, latitude]) =>
      !Number.isNaN(Number(latitude)) && !Number.isNaN(Number(longitude)),
  );

  if (!validCoordinates.length) return null;

  const totals = validCoordinates.reduce(
    (sum, [longitude, latitude]) => ({
      latitude: sum.latitude + Number(latitude),
      longitude: sum.longitude + Number(longitude),
    }),
    { latitude: 0, longitude: 0 },
  );

  return {
    latitude: totals.latitude / validCoordinates.length,
    longitude: totals.longitude / validCoordinates.length,
    zoom,
  };
}

function getCenterForControlPoints(controlPoints) {
  return getCenterFromCoordinates(
    controlPoints.map((controlPoint) => controlPoint.geoCoords),
    controlPoints.length === 1 ? 8 : 5,
  );
}

function getCenterForPlaces(places) {
  return getCenterFromCoordinates(
    places
      .filter((place) => place.geometry?.type === "Point")
      .map((place) => [place.longitude, place.latitude]),
    places.length === 1 ? 8 : 5,
  );
}

function hasValidPointCoordinates(place) {
  const latitude = Number(place.latitude);
  const longitude = Number(place.longitude);
  return !Number.isNaN(latitude) && !Number.isNaN(longitude);
}

function coordinatesEqual(first, second) {
  return first?.[0] === second?.[0] && first?.[1] === second?.[1];
}

function closeRing(coordinates) {
  if (!coordinates.length) return coordinates;
  const first = coordinates[0];
  const last = coordinates[coordinates.length - 1];
  return coordinatesEqual(first, last) ? coordinates : [...coordinates, first];
}

function featureFromGeometry(geometry, properties = {}) {
  return {
    type: "Feature",
    properties,
    geometry,
  };
}

function geometryFromBbox(bbox) {
  if (!Array.isArray(bbox) || bbox.length !== 4) return null;
  const [west, south, east, north] = bbox.map(Number);
  if (![west, south, east, north].every(Number.isFinite)) return null;
  if (west >= east || south >= north) return null;

  return {
    type: "Polygon",
    coordinates: [
      [
        [west, south],
        [east, south],
        [east, north],
        [west, north],
        [west, south],
      ],
    ],
  };
}

function lineFromCoordinates(coordinates) {
  if (coordinates.length < 2) return null;
  return coordinates;
}

function polygonFromCoordinates(coordinates) {
  if (coordinates.length < 3) return null;
  return [closeRing(coordinates)];
}

function geometryFromDraft({ geometryType, partType, coordinates, parts }) {
  switch (geometryType) {
    case "MultiPoint":
      return coordinates.length ? { type: "MultiPoint", coordinates } : null;
    case "LineString": {
      const line = lineFromCoordinates(coordinates);
      return line ? { type: "LineString", coordinates: line } : null;
    }
    case "Polygon": {
      const polygon = polygonFromCoordinates(coordinates);
      return polygon ? { type: "Polygon", coordinates: polygon } : null;
    }
    case "MultiLineString": {
      const currentLine = lineFromCoordinates(coordinates);
      const coordinatesList = currentLine ? [...parts, currentLine] : parts;
      return coordinatesList.length
        ? { type: "MultiLineString", coordinates: coordinatesList }
        : null;
    }
    case "MultiPolygon": {
      const currentPolygon = polygonFromCoordinates(coordinates);
      const coordinatesList = currentPolygon
        ? [...parts, currentPolygon]
        : parts;
      return coordinatesList.length
        ? { type: "MultiPolygon", coordinates: coordinatesList }
        : null;
    }
    case "GeometryCollection": {
      const currentPart = geometryFromDraft({
        geometryType: partType,
        partType,
        coordinates,
        parts: [],
      });
      const geometries = currentPart ? [...parts, currentPart] : parts;
      return geometries.length
        ? { type: "GeometryCollection", geometries }
        : null;
    }
    default:
      return null;
  }
}

function buildDraftFeature(draft) {
  const geometry = geometryFromDraft(draft);
  if (!geometry) return null;
  return featureFromGeometry(geometry, { label: "Draft geometry" });
}

function placeFromGeoNamesFeature(feature) {
  const coordinates = feature?.geometry?.coordinates || [];
  if (coordinates.length < 2) return null;
  const bboxGeometry = geometryFromBbox(feature.bbox);
  const sourceId = feature.id;

  return {
    id: sourceId,
    uiId: `geonames-${Date.now()}`,
    sourceId,
    label: feature?.properties?.label?.en?.[0] || "GeoNames place",
    summary: feature?.properties?.summary?.en?.[0] || "",
    longitude: coordinates[0],
    latitude: coordinates[1],
    geometry: {
      type: "Point",
      coordinates,
    },
    bbox: feature.bbox,
    bboxGeometry,
  };
}

function placeWithPointGeometry(place) {
  if (place.geometry?.type !== "Point") return place;

  return {
    ...place,
    geometry: {
      type: "Point",
      coordinates: [Number(place.longitude), Number(place.latitude)],
    },
  };
}

function parseGraphQLError(error) {
  const graphQLError = error?.graphQLErrors?.[0] || error?.errors?.[0];
  if (!graphQLError) return error?.message || "Unable to save annotation.";
  const details = graphQLError.details || graphQLError.extensions?.details;
  return details ? `${graphQLError.message}: ${details}` : graphQLError.message;
}

function WorkTabsGeoreference({ isActive, work }) {
  const [selectedFileSetId, setSelectedFileSetId] = useState(
    getDefaultFileSet(work)?.id || "",
  );
  const [mode, setMode] = useState("georeference");
  const [imageDimensions, setImageDimensions] = useState(null);
  const [pendingImageCoords, setPendingImageCoords] = useState(null);
  const [pendingGeoCoords, setPendingGeoCoords] = useState(null);
  const [gcpPairs, setGcpPairs] = useState([]);
  const [confidence, setConfidence] = useState("medium");
  const [note, setNote] = useState("");
  const [places, setPlaces] = useState([]);
  const [placeQuery, setPlaceQuery] = useState("");
  const [geoJsonInput, setGeoJsonInput] = useState("");
  const [geoJsonError, setGeoJsonError] = useState("");
  const [geoNamesResults, setGeoNamesResults] = useState([]);
  const [selectedGeoNamesPlace, setSelectedGeoNamesPlace] = useState(null);
  const [drawGeometryType, setDrawGeometryType] = useState("Point");
  const [drawCollectionPartType, setDrawCollectionPartType] = useState("Point");
  const [draftCoordinates, setDraftCoordinates] = useState([]);
  const [draftParts, setDraftParts] = useState([]);
  const [drawError, setDrawError] = useState("");
  const [mapCenter, setMapCenter] = useState(defaultMapCenter);
  const [showGeoreferencePreview, setShowGeoreferencePreview] = useState(true);

  const selectedFileSet = useMemo(
    () =>
      work?.fileSets?.find((fileSet) => fileSet.id === selectedFileSetId) ||
      null,
    [selectedFileSetId, work?.fileSets],
  );

  const georeferenceAnnotation = annotationByType(
    selectedFileSet,
    "georeference",
  );
  const navPlaceAnnotation = annotationByType(selectedFileSet, "nav_place");
  const imageServiceUrl = getImageServiceUrl(selectedFileSet);
  const canGeoreference = isImageFileSet(selectedFileSet);
  const sourceImageDimensions = useMemo(
    () => getFileSetImageDimensions(selectedFileSet) || imageDimensions,
    [imageDimensions, selectedFileSet],
  );

  const previewAnnotation = useMemo(() => {
    if (!canGeoreference || gcpPairs.length < 3 || !sourceImageDimensions)
      return null;

    return buildGeoreferenceAnnotation({
      fileSet: selectedFileSet,
      work,
      pairs: gcpPairs,
      dimensions: sourceImageDimensions,
      confidence,
      note,
      forPreview: true,
    });
  }, [
    canGeoreference,
    confidence,
    gcpPairs,
    note,
    selectedFileSet,
    sourceImageDimensions,
    work,
  ]);

  const mapMarkers = useMemo(() => {
    const gcpMarkers = gcpPairs.map((pair, index) => ({
      latitude: pair.geoCoords[1],
      longitude: pair.geoCoords[0],
      label: `GCP ${index + 1}`,
      color: "#4e2a84",
    }));

    const placeMarkers = places
      .filter(
        (place) =>
          place.geometry?.type === "Point" && hasValidPointCoordinates(place),
      )
      .map((place, index) => ({
        latitude: Number(place.latitude),
        longitude: Number(place.longitude),
        label: place.label || `Place ${index + 1}`,
        color: "#007fa3",
      }));

    const pendingMarker =
      mode === "georeference" && pendingGeoCoords
        ? [
            {
              latitude: pendingGeoCoords[1],
              longitude: pendingGeoCoords[0],
              label: `GCP ${gcpPairs.length + 1}`,
              color: "#d97706",
            },
          ]
        : [];

    if (mode === "georeference") {
      return [...gcpMarkers, ...pendingMarker];
    }

    const draftMarkers = draftCoordinates.map((coords, index) => ({
      latitude: coords[1],
      longitude: coords[0],
      label: `Draft ${index + 1}`,
      color: "#d97706",
    }));

    const selectedGeoNamesMarker = selectedGeoNamesPlace
      ? [
          {
            latitude: Number(selectedGeoNamesPlace.latitude),
            longitude: Number(selectedGeoNamesPlace.longitude),
            label: selectedGeoNamesPlace.label,
            color: "#d97706",
          },
        ]
      : [];

    return [...placeMarkers, ...selectedGeoNamesMarker, ...draftMarkers];
  }, [
    draftCoordinates,
    gcpPairs,
    mode,
    pendingGeoCoords,
    places,
    selectedGeoNamesPlace,
  ]);

  const imagePoints = useMemo(() => {
    const pairedPoints = gcpPairs.map((pair, index) => ({
      coords: pair.resourceCoords,
      label: index + 1,
    }));

    if (!pendingImageCoords) return pairedPoints;

    return [
      ...pairedPoints,
      {
        coords: pendingImageCoords,
        isPending: true,
        label: pairedPoints.length + 1,
      },
    ];
  }, [gcpPairs, pendingImageCoords]);

  const locationGeoJson = useMemo(() => {
    const features = places
      .filter((place) => place.geometry && place.geometry.type !== "Point")
      .map((place) => ({
        type: "Feature",
        properties: {
          ...(place.properties || {}),
          ...(place.label && { label: place.label }),
          ...(place.summary && { summary: place.summary }),
        },
        geometry: place.geometry,
      }));

    const draftFeature = buildDraftFeature({
      geometryType: drawGeometryType,
      partType: drawCollectionPartType,
      coordinates: draftCoordinates,
      parts: draftParts,
    });

    if (draftFeature) features.push(draftFeature);

    if (selectedGeoNamesPlace?.bboxGeometry) {
      features.push(
        featureFromGeometry(selectedGeoNamesPlace.bboxGeometry, {
          label: `${selectedGeoNamesPlace.label} bounds`,
        }),
      );
    }

    if (!features.length) return null;

    return {
      type: "FeatureCollection",
      features,
    };
  }, [
    draftCoordinates,
    draftParts,
    drawCollectionPartType,
    drawGeometryType,
    places,
    selectedGeoNamesPlace,
  ]);

  const [upsertFileSetAnnotation, { loading: isSaving }] = useMutation(
    UPSERT_FILE_SET_ANNOTATION,
    {
      refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
      awaitRefetchQueries: true,
    },
  );

  const [deleteFileSetAnnotation, { loading: isDeleting }] = useMutation(
    DELETE_FILE_SET_ANNOTATION,
    {
      refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
      awaitRefetchQueries: true,
    },
  );

  const [searchGeoNames, { loading: searchLoading }] = useLazyQuery(
    AUTHORITIES_SEARCH,
    {
      onCompleted: (data) => {
        setGeoNamesResults(data?.authoritiesSearch || []);
      },
    },
  );

  const [fetchGeoNamesPlace] = useLazyQuery(GEONAMES_PLACE, {
    onCompleted: (data) => {
      const nextPlace = placeFromGeoNamesFeature(data?.geonamesPlace);
      if (!nextPlace) return;

      setSelectedGeoNamesPlace(nextPlace);
      setMapCenter({
        latitude: nextPlace.latitude,
        longitude: nextPlace.longitude,
        zoom: 10,
      });
    },
  });

  useEffect(() => {
    const defaultFileSet = getDefaultFileSet(work);
    setSelectedFileSetId(defaultFileSet?.id || "");
  }, [work?.id]);

  useEffect(() => {
    setGcpPairs([]);
    setPendingImageCoords(null);
    setPendingGeoCoords(null);
    setImageDimensions(null);
    setGeoJsonInput("");
    setGeoJsonError("");
    setGeoNamesResults([]);
    setSelectedGeoNamesPlace(null);
    setDraftCoordinates([]);
    setDraftParts([]);
    setDrawError("");
    const nextGcpPairs = controlPointsFromGeoreferenceAnnotation(
      georeferenceAnnotation,
    );
    const nextPlaces = placesFromNavPlaceAnnotation(navPlaceAnnotation);
    setGcpPairs(nextGcpPairs);
    setPlaces(nextPlaces);
    setMapCenter(
      getCenterForControlPoints(nextGcpPairs) ||
        getCenterForPlaces(nextPlaces) ||
        defaultMapCenter,
    );
  }, [
    selectedFileSetId,
    georeferenceAnnotation?.id,
    georeferenceAnnotation?.content,
    navPlaceAnnotation?.id,
    navPlaceAnnotation?.content,
  ]);

  useEffect(() => {
    if (!pendingImageCoords || !pendingGeoCoords) return;

    setGcpPairs((current) => [
      ...current,
      {
        id: `${Date.now()}-${current.length}`,
        resourceCoords: pendingImageCoords,
        geoCoords: pendingGeoCoords,
      },
    ]);
    setPendingImageCoords(null);
    setPendingGeoCoords(null);
  }, [pendingGeoCoords, pendingImageCoords]);

  const resetLocationDraft = () => {
    setDraftCoordinates([]);
    setDraftParts([]);
    setDrawError("");
  };

  const addGeometryPlace = (geometry) => {
    setPlaces((current) => {
      const index = current.length + 1;
      const isPoint = geometry.type === "Point";
      const mapLocation = {
        uiId: `map-location-${Date.now()}`,
        label: isPoint ? `Map location ${index}` : `${geometry.type} ${index}`,
        summary: "",
        geometry,
        longitude: isPoint ? geometry.coordinates[0] : "",
        latitude: isPoint ? geometry.coordinates[1] : "",
      };

      return [...current, mapLocation];
    });
  };

  const addDraftPart = () => {
    setDrawError("");

    if (drawGeometryType === "MultiLineString") {
      const line = lineFromCoordinates(draftCoordinates);
      if (!line) {
        setDrawError("LineString parts need at least two points.");
        return;
      }
      setDraftParts((current) => [...current, line]);
      setDraftCoordinates([]);
      return;
    }

    if (drawGeometryType === "MultiPolygon") {
      const polygon = polygonFromCoordinates(draftCoordinates);
      if (!polygon) {
        setDrawError("Polygon parts need at least three points.");
        return;
      }
      setDraftParts((current) => [...current, polygon]);
      setDraftCoordinates([]);
      return;
    }

    if (drawGeometryType === "GeometryCollection") {
      const geometry = geometryFromDraft({
        geometryType: drawCollectionPartType,
        partType: drawCollectionPartType,
        coordinates: draftCoordinates,
        parts: [],
      });
      if (!geometry) {
        setDrawError(`${drawCollectionPartType} parts need more points.`);
        return;
      }
      setDraftParts((current) => [...current, geometry]);
      setDraftCoordinates([]);
    }
  };

  const finishDraftGeometry = () => {
    setDrawError("");

    const geometry = geometryFromDraft({
      geometryType: drawGeometryType,
      partType: drawCollectionPartType,
      coordinates: draftCoordinates,
      parts: draftParts,
    });

    if (!geometry) {
      setDrawError(`${drawGeometryType} needs more points.`);
      return;
    }

    addGeometryPlace(geometry);
    resetLocationDraft();
  };

  const handleMapPointSelected = (coords) => {
    if (mode === "georeference") {
      setPendingGeoCoords(coords);
      return;
    }

    setDrawError("");

    if (drawGeometryType === "Point") {
      addGeometryPlace({ type: "Point", coordinates: coords });
      setGeoNamesResults([]);
      setSelectedGeoNamesPlace(null);
      return;
    }

    if (
      drawGeometryType === "GeometryCollection" &&
      drawCollectionPartType === "Point"
    ) {
      setDraftParts((current) => [
        ...current,
        { type: "Point", coordinates: coords },
      ]);
      return;
    }

    setDraftCoordinates((current) => [...current, coords]);
  };

  const handleSearchSubmit = (event) => {
    event.preventDefault();
    if (!placeQuery.trim()) return;

    searchGeoNames({
      variables: {
        authority: "geonames",
        query: placeQuery,
      },
    });
    setSelectedGeoNamesPlace(null);
  };

  const handleGeoNamesSelected = (item) => {
    fetchGeoNamesPlace({ variables: { id: item.id } });
    setPlaceQuery("");
  };

  const addSelectedGeoNamesPlace = () => {
    if (!selectedGeoNamesPlace) return;
    setPlaces((current) => [...current, selectedGeoNamesPlace]);
    setSelectedGeoNamesPlace(null);
    setGeoNamesResults([]);
  };

  const addSelectedGeoNamesBounds = () => {
    if (!selectedGeoNamesPlace?.bboxGeometry) return;

    setPlaces((current) => [
      ...current,
      {
        uiId: `geonames-bbox-${Date.now()}`,
        id: `${selectedGeoNamesPlace.sourceId}#bbox`,
        sourceId: selectedGeoNamesPlace.sourceId,
        label: `${selectedGeoNamesPlace.label} bounds`,
        summary: selectedGeoNamesPlace.summary,
        geometry: selectedGeoNamesPlace.bboxGeometry,
        properties: {
          sourceId: selectedGeoNamesPlace.sourceId,
          bbox: selectedGeoNamesPlace.bbox,
          sourceGeometry: "bbox",
        },
        longitude: "",
        latitude: "",
      },
    ]);
    setSelectedGeoNamesPlace(null);
    setGeoNamesResults([]);
  };

  const removeGcpPair = (id) => {
    setGcpPairs((current) => current.filter((pair) => pair.id !== id));
  };

  const clearControlPoints = async () => {
    setGcpPairs([]);
    setPendingImageCoords(null);
    setPendingGeoCoords(null);

    if (!georeferenceAnnotation?.id) return;

    try {
      await deleteFileSetAnnotation({
        variables: { annotationId: georeferenceAnnotation.id },
      });
      toastWrapper("is-success", "Georeference annotation deleted");
    } catch (error) {
      toastWrapper("is-danger", parseGraphQLError(error));
    }
  };

  const removePlace = (id) => {
    setPlaces((current) => current.filter((place) => place.uiId !== id));
  };

  const updatePlace = (id, changes) => {
    setPlaces((current) =>
      current.map((place) =>
        place.uiId === id
          ? placeWithPointGeometry({ ...place, ...changes })
          : place,
      ),
    );
  };

  const handleModeChange = (nextMode) => {
    setMode(nextMode);
    setPendingImageCoords(null);
    setPendingGeoCoords(null);
    setSelectedGeoNamesPlace(null);
    resetLocationDraft();
    const nextCenter =
      nextMode === "georeference"
        ? getCenterForControlPoints(gcpPairs)
        : getCenterForPlaces(places);

    if (nextCenter) setMapCenter(nextCenter);
  };

  const applyGeoJson = () => {
    setGeoJsonError("");

    try {
      const nextPlaces = parseNavPlaceGeoJson(geoJsonInput);
      setPlaces(nextPlaces);
      setMapCenter(getCenterForPlaces(nextPlaces) || defaultMapCenter);
      setGeoJsonInput("");
    } catch (error) {
      setGeoJsonError(error.message);
    }
  };

  const canAddDraftPart =
    (drawGeometryType === "MultiLineString" && draftCoordinates.length >= 2) ||
    (drawGeometryType === "MultiPolygon" && draftCoordinates.length >= 3) ||
    (drawGeometryType === "GeometryCollection" &&
      ((drawCollectionPartType === "LineString" &&
        draftCoordinates.length >= 2) ||
        (drawCollectionPartType === "Polygon" &&
          draftCoordinates.length >= 3)));

  const canFinishDraftGeometry =
    drawGeometryType === "Point"
      ? false
      : !!geometryFromDraft({
          geometryType: drawGeometryType,
          partType: drawCollectionPartType,
          coordinates: draftCoordinates,
          parts: draftParts,
        });

  const hasDraftGeometry = !!draftCoordinates.length || !!draftParts.length;

  const saveGeoreference = async () => {
    if (!selectedFileSet || gcpPairs.length < 3 || !sourceImageDimensions)
      return;

    const annotation = buildGeoreferenceAnnotation({
      fileSet: selectedFileSet,
      work,
      pairs: gcpPairs,
      dimensions: sourceImageDimensions,
      confidence,
      note,
    });

    try {
      await upsertFileSetAnnotation({
        variables: {
          fileSetId: selectedFileSet.id,
          type: "georeference",
          content: JSON.stringify(annotation),
          language: ["en"],
        },
      });
      toastWrapper("is-success", "Georeference annotation saved");
    } catch (error) {
      toastWrapper("is-danger", parseGraphQLError(error));
    }
  };

  const saveNavPlace = async () => {
    if (!selectedFileSet) return;

    const validPlaces = places.filter(
      (place) =>
        place.geometry?.type !== "Point" || hasValidPointCoordinates(place),
    );

    if (!validPlaces.length) return;

    try {
      await upsertFileSetAnnotation({
        variables: {
          fileSetId: selectedFileSet.id,
          type: "nav_place",
          content: JSON.stringify(buildNavPlaceFeatureCollection(validPlaces)),
          language: ["en"],
        },
      });
      toastWrapper("is-success", "Location annotation saved");
    } catch (error) {
      toastWrapper("is-danger", parseGraphQLError(error));
    }
  };

  if (!work?.fileSets?.length) {
    return (
      <div data-testid="georeference-tab">
        <UITabsStickyHeader title="Georeference" />
        <Notification>
          No file sets are available for geographic annotation.
        </Notification>
      </div>
    );
  }

  return (
    <div data-testid="georeference-tab">
      <UITabsStickyHeader title="Georeference">
        <div className="buttons has-addons">
          <button
            className={`button ${mode === "georeference" ? "is-primary" : ""}`}
            onClick={() => handleModeChange("georeference")}
            type="button"
          >
            Georeference
          </button>
          <button
            className={`button ${mode === "location" ? "is-primary" : ""}`}
            onClick={() => handleModeChange("location")}
            type="button"
          >
            Location
          </button>
        </div>
      </UITabsStickyHeader>

      <div className="georeference-controls">
        <label className="label" htmlFor="georeference-file-set">
          File set
        </label>
        <div className="select">
          <select
            id="georeference-file-set"
            value={selectedFileSetId}
            onChange={(event) => setSelectedFileSetId(event.target.value)}
          >
            {work.fileSets.map((fileSet) => (
              <option key={fileSet.id} value={fileSet.id}>
                {getFileSetLabel(fileSet)}
              </option>
            ))}
          </select>
        </div>
      </div>

      {mode === "georeference" && !canGeoreference && (
        <Notification isWarning>
          Georeferencing requires a selected image file set with a IIIF image
          service.
        </Notification>
      )}

      {isActive && (
        <div className="georeference-workspace">
          {mode === "georeference" && (
            <section>
              <div className="georeference-grid">
                <div>
                  <h3 className="is-size-5 mb-3">Image coordinates</h3>
                  <ImageCoordinatePicker
                    imageServiceUrl={canGeoreference ? imageServiceUrl : ""}
                    imagePoints={imagePoints}
                    interactive
                    onDimensions={setImageDimensions}
                    onPointSelected={setPendingImageCoords}
                  />
                  {pendingImageCoords && (
                    <p className="help">
                      Selected image point: {pendingImageCoords[0]},{" "}
                      {pendingImageCoords[1]}
                    </p>
                  )}
                </div>
                <div>
                  <h3 className="is-size-5 mb-3">Map coordinates</h3>
                  <LeafletMap
                    center={mapCenter}
                    markers={mapMarkers}
                    onMapPointSelected={handleMapPointSelected}
                    previewAnnotation={
                      showGeoreferencePreview ? previewAnnotation : null
                    }
                    useCrosshairCursor
                    fitToData={!pendingImageCoords && !pendingGeoCoords}
                  />
                  <label className="checkbox mt-2">
                    <input
                      type="checkbox"
                      checked={showGeoreferencePreview}
                      disabled={!previewAnnotation}
                      onChange={(event) =>
                        setShowGeoreferencePreview(event.target.checked)
                      }
                    />{" "}
                    Preview rectified image on map
                  </label>
                  {pendingGeoCoords && (
                    <p className="help">
                      Selected map point: {pendingGeoCoords[1]},{" "}
                      {pendingGeoCoords[0]}
                    </p>
                  )}
                </div>
              </div>

              <div className="georeference-panel">
                <div className="field is-grouped">
                  <div className="control">
                    <label className="label" htmlFor="georeference-confidence">
                      Confidence
                    </label>
                    <div className="select">
                      <select
                        id="georeference-confidence"
                        value={confidence}
                        onChange={(event) => setConfidence(event.target.value)}
                      >
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                      </select>
                    </div>
                  </div>
                  <div className="control is-expanded">
                    <label className="label" htmlFor="georeference-note">
                      Note
                    </label>
                    <input
                      id="georeference-note"
                      className="input"
                      value={note}
                      onChange={(event) => setNote(event.target.value)}
                    />
                  </div>
                </div>

                <h4 className="is-size-6 has-text-weight-semibold">
                  Control points
                </h4>
                {gcpPairs.length ? (
                  <table className="table is-fullwidth is-narrow">
                    <thead>
                      <tr>
                        <th>#</th>
                        <th>Image coordinates</th>
                        <th>Map coordinates</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      {gcpPairs.map((pair, index) => (
                        <tr key={pair.id}>
                          <td>{index + 1}</td>
                          <td>{pair.resourceCoords.join(", ")}</td>
                          <td>{pair.geoCoords.join(", ")}</td>
                          <td className="has-text-right">
                            <button
                              type="button"
                              className="button is-small is-light"
                              onClick={() => removeGcpPair(pair.id)}
                            >
                              Remove
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                ) : (
                  <p className="has-text-grey">No control points added.</p>
                )}

                <div className="buttons">
                  <Button
                    isPrimary
                    disabled={
                      !canGeoreference ||
                      gcpPairs.length < 3 ||
                      !imageDimensions ||
                      isSaving ||
                      isDeleting
                    }
                    isLoading={isSaving}
                    onClick={saveGeoreference}
                  >
                    Save Georeference
                  </Button>
                  <Button
                    disabled={
                      (!gcpPairs.length && !georeferenceAnnotation) ||
                      isSaving ||
                      isDeleting
                    }
                    isLoading={isDeleting}
                    onClick={clearControlPoints}
                  >
                    Delete Control Points
                  </Button>
                </div>
              </div>
            </section>
          )}

          {mode === "location" && (
            <section>
              <div className="georeference-grid">
                <div>
                  <h3 className="is-size-5 mb-3">Image</h3>
                  <ImageCoordinatePicker
                    imageServiceUrl={canGeoreference ? imageServiceUrl : ""}
                    imagePoints={[]}
                    interactive={false}
                    onDimensions={setImageDimensions}
                    onPointSelected={() => {}}
                  />
                </div>
                <div>
                  <h3 className="is-size-5 mb-3">Map</h3>
                  <LeafletMap
                    center={mapCenter}
                    markers={mapMarkers}
                    geoJson={locationGeoJson}
                    onMapPointSelected={handleMapPointSelected}
                    useCrosshairCursor
                    fitToData={
                      mode === "location" &&
                      !hasDraftGeometry &&
                      (!selectedGeoNamesPlace ||
                        !!selectedGeoNamesPlace.bboxGeometry)
                    }
                  />
                </div>
              </div>

              <div className="georeference-panel">
                <form onSubmit={handleSearchSubmit}>
                  <label className="label" htmlFor="georeference-place-search">
                    GeoNames place
                  </label>
                  <div className="field has-addons">
                    <div className="control is-expanded">
                      <input
                        id="georeference-place-search"
                        className="input"
                        value={placeQuery}
                        onChange={(event) => setPlaceQuery(event.target.value)}
                      />
                    </div>
                    <div className="control">
                      <button className="button" type="submit">
                        Search
                      </button>
                    </div>
                  </div>
                </form>

                {searchLoading && <div className="loader mt-4"></div>}
                {selectedGeoNamesPlace && (
                  <div className="georeference-selected-place mt-3">
                    <div>
                      <strong>{selectedGeoNamesPlace.label}</strong>
                      {selectedGeoNamesPlace.summary && (
                        <span> - {selectedGeoNamesPlace.summary}</span>
                      )}
                    </div>
                    <div className="buttons mt-2">
                      <button
                        type="button"
                        className="button is-light"
                        onClick={addSelectedGeoNamesPlace}
                      >
                        Add Point
                      </button>
                      {selectedGeoNamesPlace.bboxGeometry && (
                        <button
                          type="button"
                          className="button is-light"
                          onClick={addSelectedGeoNamesBounds}
                        >
                          Add Bounds
                        </button>
                      )}
                      <button
                        type="button"
                        className="button is-light"
                        onClick={() => setSelectedGeoNamesPlace(null)}
                      >
                        Clear
                      </button>
                    </div>
                  </div>
                )}

                {!!geoNamesResults.length && (
                  <ul className="georeference-search-results">
                    {geoNamesResults.map((item) => (
                      <li key={item.id}>
                        <button
                          className="button is-text"
                          type="button"
                          onClick={() => handleGeoNamesSelected(item)}
                        >
                          <strong>{item.label}</strong>
                          {item.hint ? ` - ${item.hint}` : ""}
                        </button>
                      </li>
                    ))}
                  </ul>
                )}

                <div className="georeference-draw-controls mt-5">
                  <div className="field">
                    <label className="label" htmlFor="georeference-draw-type">
                      Geometry
                    </label>
                    <div className="select">
                      <select
                        id="georeference-draw-type"
                        value={drawGeometryType}
                        onChange={(event) => {
                          setDrawGeometryType(event.target.value);
                          resetLocationDraft();
                        }}
                      >
                        {GEOJSON_GEOMETRY_TYPES.map((geometryType) => (
                          <option key={geometryType} value={geometryType}>
                            {geometryType}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  {drawGeometryType === "GeometryCollection" && (
                    <div className="field">
                      <label
                        className="label"
                        htmlFor="georeference-collection-part-type"
                      >
                        Part
                      </label>
                      <div className="select">
                        <select
                          id="georeference-collection-part-type"
                          value={drawCollectionPartType}
                          onChange={(event) => {
                            setDrawCollectionPartType(event.target.value);
                            setDraftCoordinates([]);
                            setDrawError("");
                          }}
                        >
                          {GEOMETRY_COLLECTION_PART_TYPES.map(
                            (geometryType) => (
                              <option key={geometryType} value={geometryType}>
                                {geometryType}
                              </option>
                            ),
                          )}
                        </select>
                      </div>
                    </div>
                  )}

                  <div className="field georeference-draw-actions">
                    {(drawGeometryType === "MultiLineString" ||
                      drawGeometryType === "MultiPolygon" ||
                      drawGeometryType === "GeometryCollection") && (
                      <button
                        type="button"
                        className="button is-light"
                        disabled={!canAddDraftPart}
                        onClick={addDraftPart}
                      >
                        Add Part
                      </button>
                    )}
                    <button
                      type="button"
                      className="button is-light"
                      disabled={!canFinishDraftGeometry}
                      onClick={finishDraftGeometry}
                    >
                      Add Geometry
                    </button>
                    <button
                      type="button"
                      className="button is-light"
                      disabled={!hasDraftGeometry}
                      onClick={resetLocationDraft}
                    >
                      Clear Draft
                    </button>
                  </div>

                  {drawError && <p className="help is-danger">{drawError}</p>}
                </div>

                <details className="georeference-geojson-details mt-4">
                  <summary>Paste GeoJSON</summary>
                  <div className="field mt-3">
                    <label className="label" htmlFor="georeference-geojson">
                      GeoJSON
                    </label>
                    <textarea
                      id="georeference-geojson"
                      className="textarea"
                      rows="6"
                      value={geoJsonInput}
                      onChange={(event) => setGeoJsonInput(event.target.value)}
                      placeholder='{"type":"Feature","properties":{"label":{"en":["Place"]}},"geometry":{"type":"LineString","coordinates":[[-87.65,41.85],[-87.64,41.86]]}}'
                    />
                    {geoJsonError && (
                      <p className="help is-danger">{geoJsonError}</p>
                    )}
                    <button
                      type="button"
                      className="button is-light mt-2"
                      disabled={!geoJsonInput.trim()}
                      onClick={applyGeoJson}
                    >
                      Replace with GeoJSON
                    </button>
                  </div>
                </details>

                <h4 className="is-size-6 has-text-weight-semibold mt-5">
                  Coordinates
                </h4>
                {places.length ? (
                  <table className="table is-fullwidth is-narrow">
                    <thead>
                      <tr>
                        <th>Label</th>
                        <th>Summary</th>
                        <th>Geometry</th>
                        <th>Latitude</th>
                        <th>Longitude</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      {places.map((place) => (
                        <tr key={place.uiId}>
                          <td>
                            <input
                              aria-label={`Label for ${place.label}`}
                              className="input is-small"
                              value={place.label}
                              onChange={(event) =>
                                updatePlace(place.uiId, {
                                  label: event.target.value,
                                })
                              }
                            />
                          </td>
                          <td>
                            <input
                              aria-label={`Summary for ${place.label}`}
                              className="input is-small"
                              value={place.summary}
                              onChange={(event) =>
                                updatePlace(place.uiId, {
                                  summary: event.target.value,
                                })
                              }
                            />
                          </td>
                          <td>{place.geometry?.type || "Point"}</td>
                          <td>
                            {place.geometry?.type === "Point" ? (
                              <input
                                aria-label={`Latitude for ${place.label}`}
                                className="input is-small"
                                value={place.latitude}
                                onChange={(event) =>
                                  updatePlace(place.uiId, {
                                    latitude: event.target.value,
                                  })
                                }
                              />
                            ) : (
                              <span className="has-text-grey">-</span>
                            )}
                          </td>
                          <td>
                            {place.geometry?.type === "Point" ? (
                              <input
                                aria-label={`Longitude for ${place.label}`}
                                className="input is-small"
                                value={place.longitude}
                                onChange={(event) =>
                                  updatePlace(place.uiId, {
                                    longitude: event.target.value,
                                  })
                                }
                              />
                            ) : (
                              <span className="has-text-grey">-</span>
                            )}
                          </td>
                          <td className="has-text-right">
                            <button
                              type="button"
                              className="button is-small is-light"
                              onClick={() => removePlace(place.uiId)}
                            >
                              Remove
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                ) : (
                  <p className="has-text-grey">No places added.</p>
                )}

                <Button
                  isPrimary
                  disabled={!places.length || isSaving}
                  isLoading={isSaving}
                  onClick={saveNavPlace}
                >
                  Save Location
                </Button>
              </div>
            </section>
          )}
        </div>
      )}
    </div>
  );
}

WorkTabsGeoreference.propTypes = {
  isActive: PropTypes.bool,
  work: PropTypes.object,
};

export default WorkTabsGeoreference;
