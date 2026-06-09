import React, { useEffect, useRef, useState } from "react";
import PropTypes from "prop-types";

function LeafletMap({
  center,
  fitToData,
  geoJson,
  markers,
  onMapPointSelected,
  previewAnnotation,
  useCrosshairCursor,
}) {
  const containerRef = useRef(null);
  const mapRef = useRef(null);
  const geoJsonLayerRef = useRef(null);
  const markerLayerRef = useRef(null);
  const onMapPointSelectedRef = useRef(onMapPointSelected);
  const warpedLayerRef = useRef(null);
  const [mapReady, setMapReady] = useState(false);

  useEffect(() => {
    onMapPointSelectedRef.current = onMapPointSelected;
  }, [onMapPointSelected]);

  useEffect(() => {
    if (!mapReady || !mapRef.current) return;

    mapRef.current
      .getContainer()
      .classList.toggle("leaflet-crosshair", useCrosshairCursor);
  }, [mapReady, useCrosshairCursor]);

  const refreshMap = () => {
    if (!mapRef.current) return;

    mapRef.current.invalidateSize();
  };

  const queueMapRefresh = () => {
    window.requestAnimationFrame(() => {
      refreshMap();
      window.requestAnimationFrame(refreshMap);
    });
    window.setTimeout(refreshMap, 0);
    window.setTimeout(refreshMap, 100);
  };

  useEffect(() => {
    let isMounted = true;

    async function initializeMap() {
      if (!containerRef.current || mapRef.current) return;

      const L = await import("leaflet");
      if (!isMounted) return;

      mapRef.current = L.map(containerRef.current, {
        center: [center.latitude, center.longitude],
        zoom: center.zoom,
      });

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "&copy; OpenStreetMap contributors",
      }).addTo(mapRef.current);

      markerLayerRef.current = L.layerGroup().addTo(mapRef.current);
      mapRef.current.on("click", (event) => {
        onMapPointSelectedRef.current([
          Number(event.latlng.lng.toFixed(5)),
          Number(event.latlng.lat.toFixed(5)),
        ]);
      });
      mapRef.current.on("dragstart", () => {
        mapRef.current?.getContainer().classList.add("leaflet-dragging");
      });
      mapRef.current.on("dragend", () => {
        mapRef.current?.getContainer().classList.remove("leaflet-dragging");
      });
      setMapReady(true);
      queueMapRefresh();
    }

    initializeMap();

    return () => {
      isMounted = false;
      setMapReady(false);
      mapRef.current?.remove();
      mapRef.current = null;
      geoJsonLayerRef.current = null;
      markerLayerRef.current = null;
      warpedLayerRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (!mapReady || !mapRef.current) return;
    if (fitToData) return;
    mapRef.current.setView([center.latitude, center.longitude], center.zoom);
    queueMapRefresh();
    // `fitToData` is intentionally omitted: we only recenter when the caller
    // supplies a new `center`, not when toggling fit mode on/off (which would
    // snap the map back to a stale center while drawing).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [center.latitude, center.longitude, center.zoom, mapReady]);

  useEffect(() => {
    let isMounted = true;

    async function renderMarkers() {
      if (!mapReady || !mapRef.current || !markerLayerRef.current) return;
      const L = await import("leaflet");
      if (!isMounted || !markerLayerRef.current) return;

      markerLayerRef.current.clearLayers();
      markers.forEach((marker, index) => {
        L.circleMarker([marker.latitude, marker.longitude], {
          radius: 6,
          color: marker.color || "#4e2a84",
          fillColor: marker.color || "#4e2a84",
          fillOpacity: 0.8,
          weight: 2,
        })
          .bindTooltip(marker.label || `Point ${index + 1}`)
          .addTo(markerLayerRef.current);
      });
      markerLayerRef.current.bringToFront();
      queueMapRefresh();
    }

    renderMarkers();
    return () => {
      isMounted = false;
    };
  }, [mapReady, markers]);

  useEffect(() => {
    let isMounted = true;

    async function renderGeoJson() {
      if (!mapReady || !mapRef.current) return;
      const L = await import("leaflet");
      if (!isMounted || !mapRef.current) return;

      if (geoJsonLayerRef.current) {
        geoJsonLayerRef.current.remove();
        geoJsonLayerRef.current = null;
      }

      if (!geoJson?.features?.length) return;

      geoJsonLayerRef.current = L.geoJSON(geoJson, {
        pointToLayer: (_feature, latLng) =>
          L.circleMarker(latLng, {
            radius: 6,
            color: "#007fa3",
            fillColor: "#007fa3",
            fillOpacity: 0.8,
            weight: 2,
          }),
        style: {
          color: "#007fa3",
          fillColor: "#007fa3",
          fillOpacity: 0.18,
          weight: 2,
        },
        onEachFeature: (feature, layer) => {
          const label = feature?.properties?.label;
          if (label) layer.bindTooltip(formatLabel(label));
        },
      }).addTo(mapRef.current);
      queueMapRefresh();
    }

    renderGeoJson();
    return () => {
      isMounted = false;
    };
  }, [geoJson, mapReady]);

  useEffect(() => {
    let isMounted = true;

    async function fitDataBounds() {
      if (!fitToData || !mapReady || !mapRef.current) return;
      const L = await import("leaflet");
      if (!isMounted || !mapRef.current) return;

      const bounds = L.latLngBounds([]);
      markers.forEach((marker) => {
        bounds.extend([marker.latitude, marker.longitude]);
      });

      if (geoJson?.features?.length) {
        const geoJsonBounds = L.geoJSON(geoJson).getBounds();
        if (geoJsonBounds.isValid()) bounds.extend(geoJsonBounds);
      }

      // Nothing to fit to: leave the map where the user has it rather than
      // snapping back to the default center.
      if (!bounds.isValid()) return;

      if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
        mapRef.current.setView(bounds.getCenter(), 8);
        queueMapRefresh();
        return;
      }

      mapRef.current.fitBounds(bounds, { maxZoom: 12, padding: [32, 32] });
      queueMapRefresh();
    }

    fitDataBounds();
    return () => {
      isMounted = false;
    };
  }, [
    center.latitude,
    center.longitude,
    center.zoom,
    fitToData,
    geoJson,
    mapReady,
    markers,
  ]);

  useEffect(() => {
    let isMounted = true;

    async function renderWarpedLayer() {
      if (!mapRef.current) return;

      if (warpedLayerRef.current) {
        warpedLayerRef.current.remove();
        warpedLayerRef.current = null;
      }

      if (!previewAnnotation) return;

      const { WarpedMapLayer } = await import("@allmaps/leaflet");
      if (!isMounted || !mapRef.current) return;

      warpedLayerRef.current = new WarpedMapLayer(previewAnnotation, {
        opacity: 0.65,
      });
      warpedLayerRef.current.addTo(mapRef.current);
    }

    renderWarpedLayer();

    return () => {
      isMounted = false;
    };
  }, [previewAnnotation]);

  return (
    <div
      className="georeference-map"
      data-testid="georeference-map"
      ref={containerRef}
    />
  );
}

function formatLabel(label) {
  if (typeof label === "string") return label;
  if (!label || typeof label !== "object") return "";

  const values = Object.values(label).find(
    (entry) => Array.isArray(entry) && entry.length,
  );
  return values?.[0] || "";
}

LeafletMap.propTypes = {
  center: PropTypes.shape({
    latitude: PropTypes.number,
    longitude: PropTypes.number,
    zoom: PropTypes.number,
  }).isRequired,
  fitToData: PropTypes.bool,
  geoJson: PropTypes.object,
  markers: PropTypes.arrayOf(PropTypes.object),
  onMapPointSelected: PropTypes.func.isRequired,
  previewAnnotation: PropTypes.object,
  useCrosshairCursor: PropTypes.bool,
};

LeafletMap.defaultProps = {
  fitToData: false,
  geoJson: null,
  markers: [],
  useCrosshairCursor: false,
};

export default LeafletMap;
