export const GEOREFERENCE_CONTEXT =
  "http://iiif.io/api/extension/georef/1/context.json";
export const NAV_PLACE_CONTEXT =
  "http://iiif.io/api/extension/navplace/context.json";
export const PRESENTATION_CONTEXT =
  "http://iiif.io/api/presentation/3/context.json";
export const GEOJSON_GEOMETRY_TYPES = [
  "Point",
  "LineString",
  "Polygon",
  "MultiPoint",
  "MultiLineString",
  "MultiPolygon",
  "GeometryCollection",
];

export function annotationByType(fileSet, type) {
  return fileSet?.annotations?.find((annotation) => annotation.type === type);
}

export function parseAnnotationContent(annotation) {
  if (!annotation?.content) return null;

  try {
    return JSON.parse(annotation.content);
  } catch (_error) {
    return null;
  }
}

export function getFileSetLabel(fileSet) {
  return (
    fileSet?.coreMetadata?.label ||
    fileSet?.coreMetadata?.originalFilename ||
    fileSet?.accessionNumber ||
    fileSet?.id ||
    "Untitled file set"
  );
}

export function getDefaultFileSet(work) {
  const fileSets = work?.fileSets || [];
  if (!fileSets.length) return null;

  const representativeId = work?.representativeImage?.split("/").pop();
  const representative = fileSets.find(
    (fileSet) => fileSet.id === representativeId,
  );
  if (representative) return representative;

  return fileSets.find((fileSet) => fileSet.role?.id === "A") || fileSets[0];
}

export function isImageFileSet(fileSet) {
  const mimeType = fileSet?.coreMetadata?.mimeType || "";
  return (
    Boolean(fileSet?.representativeImageUrl) && mimeType.startsWith("image")
  );
}

export function getImageServiceUrl(fileSet) {
  return fileSet?.representativeImageUrl || "";
}

function parseExtractedMetadata(fileSet) {
  const metadata = fileSet?.extractedMetadata;
  if (!metadata) return null;
  if (typeof metadata !== "string") return metadata;

  try {
    return JSON.parse(metadata);
  } catch (_error) {
    return null;
  }
}

function validDimension(value) {
  const dimension = Number(value);
  return Number.isFinite(dimension) && dimension > 0 ? dimension : null;
}

export function getFileSetImageDimensions(fileSet) {
  const metadata = parseExtractedMetadata(fileSet);
  const width =
    validDimension(fileSet?.width) ||
    validDimension(metadata?.exif?.value?.ImageWidth);
  const height =
    validDimension(fileSet?.height) ||
    validDimension(metadata?.exif?.value?.ImageHeight);

  return width && height ? { width, height } : null;
}

export function getCanvasSourceId(work, fileSet) {
  if (work?.manifestUrl) {
    return work.manifestUrl.replace(
      /\/works\/[^?]+.*/,
      `/file-sets/${fileSet.id}?as=iiif`,
    );
  }

  return getImageServiceUrl(fileSet);
}

function formatSvgNumber(value) {
  return Number(Number(value).toFixed(2)).toString();
}

function buildFullImageSelector(dimensions) {
  if (!dimensions?.width || !dimensions?.height) return undefined;
  const width = formatSvgNumber(dimensions.width);
  const height = formatSvgNumber(dimensions.height);

  return {
    type: "SvgSelector",
    value: `<svg width="${width}" height="${height}"><polygon points="0,0 ${width},0 ${width},${height} 0,${height}" /></svg>`,
  };
}

export function buildGeoreferenceAnnotation({
  fileSet,
  work,
  pairs,
  dimensions,
  confidence = "medium",
  note = "",
  forPreview = false,
}) {
  if (!fileSet || !pairs.length) return null;

  const imageServiceUrl = getImageServiceUrl(fileSet);
  const source = forPreview
    ? {
        id: imageServiceUrl.replace("/iiif/3/", "/iiif/2/"),
        type: imageServiceUrl.includes("/iiif/2/")
          ? "ImageService2"
          : "ImageService2",
      }
    : {
        id: getCanvasSourceId(work, fileSet),
        type: "Canvas",
      };

  return {
    "@context": [GEOREFERENCE_CONTEXT, PRESENTATION_CONTEXT],
    id: `urn:meadow:georeference:${fileSet.id}:${encodeURIComponent(
      new Date().toISOString(),
    )}`,
    type: "Annotation",
    motivation: "georeferencing",
    target: {
      type: "SpecificResource",
      source: {
        ...source,
        ...(dimensions?.height && { height: dimensions.height }),
        ...(dimensions?.width && { width: dimensions.width }),
      },
      ...(dimensions && { selector: buildFullImageSelector(dimensions) }),
    },
    body: {
      type: "FeatureCollection",
      features: pairs.map((pair) => ({
        type: "Feature",
        properties: {
          confidence,
          ...(note && { note }),
          resourceCoords: pair.resourceCoords,
        },
        geometry: {
          type: "Point",
          coordinates: pair.geoCoords,
        },
      })),
    },
  };
}

export function buildNavPlaceFeatureCollection(places) {
  return {
    "@context": [NAV_PLACE_CONTEXT, PRESENTATION_CONTEXT],
    type: "FeatureCollection",
    features: places.map((place) => {
      const feature = {
        type: "Feature",
        properties: {
          ...(place.properties || {}),
          ...(place.label && { label: toLanguageMap(place.label) }),
          ...(place.summary && { summary: toLanguageMap(place.summary) }),
          ...(place.sourceId && { sourceId: place.sourceId }),
        },
        geometry:
          "geometry" in place
            ? place.geometry
            : {
                type: "Point",
                coordinates: [Number(place.longitude), Number(place.latitude)],
              },
      };

      if (isHttpUri(place.id)) feature.id = place.id;

      return feature;
    }),
  };
}

export function parseNavPlaceGeoJson(value) {
  let parsed;

  try {
    parsed = JSON.parse(value);
  } catch (_error) {
    throw new Error("GeoJSON must be valid JSON.");
  }

  return placesFromGeoJson(parsed);
}

export function placesFromGeoJson(geoJson) {
  const featureCollection = normalizeGeoJsonToFeatureCollection(geoJson);

  return featureCollection.features.map((feature, index) =>
    placeFromFeature(feature, `geojson-${Date.now()}-${index}`),
  );
}

export function normalizeGeoJsonToFeatureCollection(geoJson) {
  if (!geoJson || typeof geoJson !== "object") {
    throw new Error("GeoJSON must be an object.");
  }

  if (geoJson.type === "FeatureCollection") {
    if (!Array.isArray(geoJson.features)) {
      throw new Error("FeatureCollection must include a features array.");
    }

    return {
      "@context": geoJson["@context"],
      type: "FeatureCollection",
      features: geoJson.features.map(normalizeFeature),
    };
  }

  if (geoJson.type === "Feature") {
    return {
      type: "FeatureCollection",
      features: [normalizeFeature(geoJson)],
    };
  }

  if (GEOJSON_GEOMETRY_TYPES.includes(geoJson.type)) {
    return {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          properties: {},
          geometry: geoJson,
        },
      ],
    };
  }

  throw new Error(
    "GeoJSON must be a FeatureCollection, Feature, or geometry object.",
  );
}

function normalizeFeature(feature) {
  if (!feature || feature.type !== "Feature") {
    throw new Error("FeatureCollection entries must be Feature objects.");
  }

  if (
    feature.geometry !== null &&
    !GEOJSON_GEOMETRY_TYPES.includes(feature.geometry?.type)
  ) {
    throw new Error("Feature geometry must be a valid GeoJSON geometry type.");
  }

  if (feature.geometry !== null && !isValidGeoJsonGeometry(feature.geometry)) {
    throw new Error("Feature geometry coordinates are not valid GeoJSON.");
  }

  return {
    ...feature,
    properties: feature.properties || {},
  };
}

function isValidGeoJsonGeometry(geometry) {
  switch (geometry?.type) {
    case "Point":
      return isValidPosition(geometry.coordinates);
    case "MultiPoint":
      return (
        Array.isArray(geometry.coordinates) &&
        geometry.coordinates.every(isValidPosition)
      );
    case "LineString":
      return isValidLineString(geometry.coordinates);
    case "MultiLineString":
      return (
        Array.isArray(geometry.coordinates) &&
        geometry.coordinates.every(isValidLineString)
      );
    case "Polygon":
      return isValidPolygon(geometry.coordinates);
    case "MultiPolygon":
      return (
        Array.isArray(geometry.coordinates) &&
        geometry.coordinates.every(isValidPolygon)
      );
    case "GeometryCollection":
      return (
        Array.isArray(geometry.geometries) &&
        geometry.geometries.every(isValidGeoJsonGeometry)
      );
    default:
      return false;
  }
}

function isValidLineString(coordinates) {
  return (
    Array.isArray(coordinates) &&
    coordinates.length >= 2 &&
    coordinates.every(isValidPosition)
  );
}

function isValidPolygon(coordinates) {
  return (
    Array.isArray(coordinates) &&
    coordinates.length > 0 &&
    coordinates.every(isValidLinearRing)
  );
}

function isValidLinearRing(coordinates) {
  return (
    Array.isArray(coordinates) &&
    coordinates.length >= 4 &&
    coordinates.every(isValidPosition) &&
    JSON.stringify(coordinates[0]) ===
      JSON.stringify(coordinates[coordinates.length - 1])
  );
}

function isValidPosition(position) {
  if (!Array.isArray(position) || position.length < 2) return false;
  const [longitude, latitude, ...rest] = position;

  return (
    Number.isFinite(longitude) &&
    Number.isFinite(latitude) &&
    longitude >= -180 &&
    longitude <= 180 &&
    latitude >= -90 &&
    latitude <= 90 &&
    rest.every(Number.isFinite)
  );
}

function firstLanguageMapValue(value) {
  if (typeof value === "string") return value;
  if (!value || typeof value !== "object") return "";

  const values = Object.values(value).find(
    (entry) => Array.isArray(entry) && entry.length,
  );
  return values?.[0] || "";
}

function toLanguageMap(value) {
  if (!value) return undefined;
  if (typeof value === "object") return value;
  return { en: [value] };
}

function isHttpUri(value) {
  return /^https?:\/\//i.test(value || "");
}

export function placesFromNavPlaceAnnotation(annotation) {
  const content = parseAnnotationContent(annotation);
  if (!content) return [];

  try {
    const featureCollection = normalizeGeoJsonToFeatureCollection(content);
    return featureCollection.features.map((feature, index) =>
      placeFromFeature(
        feature,
        feature.id || `${annotation.id || "nav-place"}-${index}`,
      ),
    );
  } catch (_error) {
    return [];
  }
}

function placeFromFeature(feature, uiId) {
  const geometry = feature?.geometry || null;
  const coordinates = geometry?.coordinates || [];
  const isPoint = geometry?.type === "Point" && coordinates.length >= 2;
  const properties = feature.properties || {};

  return {
    id: feature.id || "",
    sourceId: properties.sourceId || "",
    uiId,
    label: firstLanguageMapValue(properties.label) || "Location",
    summary: firstLanguageMapValue(properties.summary),
    properties,
    geometry,
    longitude: isPoint ? coordinates[0] : "",
    latitude: isPoint ? coordinates[1] : "",
  };
}

export function controlPointsFromGeoreferenceAnnotation(annotation) {
  const content = parseAnnotationContent(annotation);
  const features = Array.isArray(content?.body?.features)
    ? content.body.features
    : [];

  return features
    .map((feature, index) => {
      const resourceCoords = feature?.properties?.resourceCoords || [];
      const geoCoords = feature?.geometry?.coordinates || [];
      if (resourceCoords.length < 2 || geoCoords.length < 2) return null;

      const nextResourceCoords = [
        Number(resourceCoords[0]),
        Number(resourceCoords[1]),
      ];
      const nextGeoCoords = [Number(geoCoords[0]), Number(geoCoords[1])];

      if (
        nextResourceCoords.some(Number.isNaN) ||
        nextGeoCoords.some(Number.isNaN)
      ) {
        return null;
      }

      return {
        id: feature.id || `${annotation.id || "georeference"}-${index}`,
        resourceCoords: nextResourceCoords,
        geoCoords: nextGeoCoords,
      };
    })
    .filter(Boolean);
}
