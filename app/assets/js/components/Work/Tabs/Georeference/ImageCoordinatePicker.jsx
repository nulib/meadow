import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import PropTypes from "prop-types";
import CloverImage from "@samvera/clover-iiif/image";
import {
  FiCrosshair,
  FiHome,
  FiMaximize,
  FiMinimize,
  FiZoomIn,
  FiZoomOut,
} from "react-icons/fi";

function ImageCoordinatePicker({
  imageServiceUrl,
  imagePoints = [],
  interactive = true,
  onDimensions,
  onPointSelected,
}) {
  const shellRef = useRef(null);
  const containerRef = useRef(null);
  const viewerRef = useRef(null);
  const viewerCleanupRef = useRef(null);
  const imagePointsRef = useRef(imagePoints);
  const markerFrameRef = useRef(null);
  const interactiveRef = useRef(interactive);
  const onDimensionsRef = useRef(onDimensions);
  const onPointSelectedRef = useRef(onPointSelected);
  const hasRefreshedInitialTileRef = useRef(false);
  const hasInitializedViewRef = useRef(false);
  const [viewerReady, setViewerReady] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isPanning, setIsPanning] = useState(false);
  const [imagePointMarkers, setImagePointMarkers] = useState([]);
  const activeCursor = isPanning
    ? "grabbing"
    : interactive
      ? "crosshair"
      : "grab";

  useEffect(() => {
    interactiveRef.current = interactive;
  }, [interactive]);

  useEffect(() => {
    onDimensionsRef.current = onDimensions;
  }, [onDimensions]);

  useEffect(() => {
    onPointSelectedRef.current = onPointSelected;
  }, [onPointSelected]);

  const updateImagePointMarkers = useCallback(() => {
    const viewer = viewerRef.current;
    const container = containerRef.current;
    const viewerElement = viewer?.element;
    if (!viewer || !container || !viewerElement || !viewer.viewport) return;

    const item = viewer.world?.getItemAt?.(0);
    if (!item) {
      setImagePointMarkers([]);
      return;
    }

    const viewerRect = viewerElement.getBoundingClientRect();
    const containerRect = container.getBoundingClientRect();
    const offsetLeft = viewerRect.left - containerRect.left;
    const offsetTop = viewerRect.top - containerRect.top;

    const nextMarkers = imagePointsRef.current
      .map((point, index) => {
        if (!point?.coords?.length) return null;

        const viewportPoint = item.imageToViewportCoordinates
          ? item.imageToViewportCoordinates(
              point.coords[0],
              point.coords[1],
              true,
            )
          : viewer.viewport.imageToViewportCoordinates(
              point.coords[0],
              point.coords[1],
            );
        const pixelPoint = viewer.viewport.pixelFromPoint(viewportPoint, true);

        return {
          key: `${point.label || index + 1}-${point.coords[0]}-${point.coords[1]}-${point.isPending ? "pending" : "saved"}`,
          label: point.label || index + 1,
          isPending: Boolean(point.isPending),
          left: pixelPoint.x + offsetLeft,
          top: pixelPoint.y + offsetTop,
        };
      })
      .filter(Boolean);

    setImagePointMarkers((currentMarkers) => {
      const hasChanged =
        currentMarkers.length !== nextMarkers.length ||
        currentMarkers.some((marker, index) => {
          const nextMarker = nextMarkers[index];
          return (
            marker.key !== nextMarker.key ||
            marker.label !== nextMarker.label ||
            marker.isPending !== nextMarker.isPending ||
            Math.abs(marker.left - nextMarker.left) > 0.5 ||
            Math.abs(marker.top - nextMarker.top) > 0.5
          );
        });

      return hasChanged ? nextMarkers : currentMarkers;
    });
  }, []);

  const scheduleImagePointMarkerUpdate = useCallback(() => {
    if (markerFrameRef.current) return;

    markerFrameRef.current = window.requestAnimationFrame(() => {
      markerFrameRef.current = null;
      updateImagePointMarkers();
    });
  }, [updateImagePointMarkers]);

  const refreshViewer = useCallback(() => {
    const viewer = viewerRef.current;
    if (!viewer) return;

    viewer.forceResize();
    viewer.viewport?.applyConstraints();
    viewer.forceRedraw?.();
  }, []);

  const queueViewerRefresh = useCallback(() => {
    window.requestAnimationFrame(() => {
      refreshViewer();
      window.requestAnimationFrame(refreshViewer);
    });
    window.setTimeout(refreshViewer, 0);
    window.setTimeout(refreshViewer, 100);
    window.setTimeout(refreshViewer, 300);
  }, [refreshViewer]);

  const applyViewerCursor = useCallback(() => {
    if (!containerRef.current) return;

    [
      containerRef.current,
      ...containerRef.current.querySelectorAll("*"),
    ].forEach((element) =>
      element.style.setProperty("cursor", activeCursor, "important"),
    );
  }, [activeCursor]);

  useEffect(() => {
    applyViewerCursor();
  }, [applyViewerCursor, viewerReady]);

  const cloverImageConfig = useMemo(
    () => ({
      immediateRender: true,
      showNavigationControl: false,
      showNavigator: true,
      showRotationControl: false,
      gestureSettingsMouse: {
        clickToZoom: false,
        dragToPan: true,
        scrollToZoom: true,
      },
      gestureSettingsPen: {
        clickToZoom: false,
        dragToPan: true,
      },
      gestureSettingsTouch: {
        clickToZoom: false,
        dragToPan: true,
      },
    }),
    [],
  );

  const handleViewerReady = useCallback(() => {
    const viewer = viewerRef.current;
    if (!viewer) return;

    setViewerReady(true);
    scheduleImagePointMarkerUpdate();

    // Home/dimensions only need to run once per loaded image, not on every
    // tile-loaded event (which would keep snapping the view back to home).
    if (hasInitializedViewRef.current) return;
    if (!viewer.world?.getItemCount?.()) return;
    hasInitializedViewRef.current = true;

    viewer.viewport?.goHome(true);
    queueViewerRefresh();

    const item = viewer.world?.getItemAt(0);
    const size = item?.getContentSize?.();
    if (size?.x && size?.y) {
      onDimensionsRef.current({
        width: Math.round(size.x),
        height: Math.round(size.y),
      });
    }
  }, [queueViewerRefresh, scheduleImagePointMarkerUpdate]);

  const handleOpenSeadragonCallback = useCallback(
    (viewer) => {
      if (!viewer || viewerRef.current === viewer) return;

      viewerCleanupRef.current?.();
      viewerRef.current = viewer;
      hasRefreshedInitialTileRef.current = false;
      hasInitializedViewRef.current = false;
      setViewerReady(false);
      setIsPanning(false);

      const handleCanvasClick = (event) => {
        if (!interactiveRef.current) return;
        if (event.quick === false) return;

        event.preventDefaultAction = true;
        const viewportPoint = viewer.viewport.pointFromPixel(event.position);
        const imagePoint =
          viewer.viewport.viewportToImageCoordinates(viewportPoint);

        onPointSelectedRef.current([
          Number(imagePoint.x.toFixed(2)),
          Number(imagePoint.y.toFixed(2)),
        ]);
      };
      const handlePanning = () => setIsPanning(true);
      const handlePanningEnd = () => setIsPanning(false);
      const handleInitialTileLoaded = () => {
        // Clover loads images via addTiledImage/addSimpleImage and never calls
        // viewer.open(), so the Viewer "open" event never fires. tile-loaded is
        // the first reliable Viewer event once the image is on screen, so use it
        // to mark the viewer ready.
        handleViewerReady();
        if (hasRefreshedInitialTileRef.current) return;
        hasRefreshedInitialTileRef.current = true;
        queueViewerRefresh();
        scheduleImagePointMarkerUpdate();
      };
      const handleViewportUpdate = () => scheduleImagePointMarkerUpdate();

      viewer.addHandler("canvas-click", handleCanvasClick);
      viewer.addHandler("canvas-drag", handlePanning);
      viewer.addHandler("canvas-drag-end", handlePanningEnd);
      viewer.addHandler("canvas-release", handlePanningEnd);
      viewer.addHandler("canvas-exit", handlePanningEnd);
      viewer.addHandler("open", handleViewerReady);
      viewer.addHandler("tile-loaded", handleInitialTileLoaded);
      viewer.addHandler("animation", handleViewportUpdate);
      viewer.addHandler("animation-finish", handleViewportUpdate);
      viewer.addHandler("resize", handleViewportUpdate);
      viewer.addHandler("update-viewport", handleViewportUpdate);
      // "add-item" is raised on the World, not the Viewer.
      viewer.world?.addHandler("add-item", handleViewerReady);

      viewerCleanupRef.current = () => {
        viewer.removeHandler("canvas-click", handleCanvasClick);
        viewer.removeHandler("canvas-drag", handlePanning);
        viewer.removeHandler("canvas-drag-end", handlePanningEnd);
        viewer.removeHandler("canvas-release", handlePanningEnd);
        viewer.removeHandler("canvas-exit", handlePanningEnd);
        viewer.removeHandler("open", handleViewerReady);
        viewer.removeHandler("tile-loaded", handleInitialTileLoaded);
        viewer.removeHandler("animation", handleViewportUpdate);
        viewer.removeHandler("animation-finish", handleViewportUpdate);
        viewer.removeHandler("resize", handleViewportUpdate);
        viewer.removeHandler("update-viewport", handleViewportUpdate);
        viewer.world?.removeHandler("add-item", handleViewerReady);
      };

      if (viewer.world?.getItemCount?.() > 0) handleViewerReady();
      queueViewerRefresh();
      scheduleImagePointMarkerUpdate();
      applyViewerCursor();
    },
    [
      applyViewerCursor,
      handleViewerReady,
      queueViewerRefresh,
      scheduleImagePointMarkerUpdate,
    ],
  );

  useEffect(() => {
    setViewerReady(false);
    setIsPanning(false);
    setImagePointMarkers([]);
    hasRefreshedInitialTileRef.current = false;
    hasInitializedViewRef.current = false;
    viewerRef.current?.clearOverlays?.();
  }, [imageServiceUrl]);

  useEffect(() => {
    imagePointsRef.current = imagePoints;
    scheduleImagePointMarkerUpdate();
  }, [imagePoints, scheduleImagePointMarkerUpdate]);

  useEffect(
    () => () => {
      viewerCleanupRef.current?.();
      if (markerFrameRef.current) {
        window.cancelAnimationFrame(markerFrameRef.current);
      }
      viewerCleanupRef.current = null;
      markerFrameRef.current = null;
      viewerRef.current = null;
    },
    [],
  );

  useEffect(() => {
    if (!shellRef.current || typeof ResizeObserver === "undefined") return;

    const resizeObserver = new ResizeObserver(() => {
      queueViewerRefresh();
      scheduleImagePointMarkerUpdate();
    });
    resizeObserver.observe(shellRef.current);

    return () => resizeObserver.disconnect();
  }, [queueViewerRefresh, scheduleImagePointMarkerUpdate]);

  useEffect(() => {
    const handleFullscreenChange = () => {
      const isViewerFullscreen =
        document.fullscreenElement === shellRef.current;
      setIsFullscreen(isViewerFullscreen);
      queueViewerRefresh();
      scheduleImagePointMarkerUpdate();
    };

    document.addEventListener("fullscreenchange", handleFullscreenChange);
    return () =>
      document.removeEventListener("fullscreenchange", handleFullscreenChange);
  }, [queueViewerRefresh, scheduleImagePointMarkerUpdate]);

  const zoomBy = (factor) => {
    const viewer = viewerRef.current;
    if (!viewer) return;

    viewer.viewport.zoomBy(factor);
    viewer.viewport.applyConstraints();
    scheduleImagePointMarkerUpdate();
  };

  const goHome = () => {
    viewerRef.current?.viewport.goHome();
    scheduleImagePointMarkerUpdate();
  };

  const toggleFullscreen = async () => {
    if (!shellRef.current) return;

    if (document.fullscreenElement) {
      await document.exitFullscreen();
      return;
    }

    await shellRef.current.requestFullscreen();
  };

  if (!imageServiceUrl) {
    return (
      <div className="georeference-empty" data-testid="image-picker-empty">
        No IIIF image service is available for this file set.
      </div>
    );
  }

  return (
    <div
      className="georeference-image-picker"
      data-testid="georeference-image-picker"
      ref={shellRef}
      style={{ position: "relative" }}
    >
      <div
        className="georeference-image-instructions"
        style={{
          alignItems: "center",
          color: "white",
          display: "flex",
          fontSize: "0.75rem",
          gap: "0.35rem",
          left: "0.75rem",
          lineHeight: 1,
          pointerEvents: "none",
          position: "absolute",
          top: "0.75rem",
          zIndex: 2,
        }}
      >
        {interactive ? <FiCrosshair aria-hidden /> : <FiHome aria-hidden />}
        <span>
          {interactive
            ? "Click image to place a control point"
            : "Inspect the image, then click the map to place it"}
        </span>
      </div>
      <div
        className={`georeference-image-canvas ${
          isPanning
            ? "is-panning"
            : interactive
              ? "is-placing-control-point"
              : "is-inspecting"
        }`}
        ref={containerRef}
        style={{
          cursor: activeCursor,
          height: "100%",
          position: "relative",
          width: "100%",
        }}
      >
        <CloverImage
          instanceId="georeference-image-coordinate-picker"
          src={imageServiceUrl.replace(/\/$/, "")}
          isTiledImage
          label="Georeference source image"
          openSeadragonConfig={cloverImageConfig}
          openSeadragonCallback={handleOpenSeadragonCallback}
        />
        <div
          aria-hidden="true"
          className="georeference-image-point-layer"
          style={{
            inset: 0,
            pointerEvents: "none",
            position: "absolute",
            zIndex: 1,
          }}
        >
          {viewerReady &&
            imagePointMarkers.map((marker) => (
              <div
                key={marker.key}
                className={`georeference-image-point${
                  marker.isPending ? " is-pending" : ""
                }`}
                style={{
                  left: `${marker.left}px`,
                  position: "absolute",
                  top: `${marker.top}px`,
                  transform: "translate(-50%, -50%)",
                }}
              >
                {marker.label}
              </div>
            ))}
        </div>
      </div>
    </div>
  );
}

ImageCoordinatePicker.propTypes = {
  imageServiceUrl: PropTypes.string,
  imagePoints: PropTypes.arrayOf(
    PropTypes.shape({
      coords: PropTypes.arrayOf(PropTypes.number).isRequired,
      isPending: PropTypes.bool,
      label: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
    }),
  ),
  interactive: PropTypes.bool,
  onDimensions: PropTypes.func.isRequired,
  onPointSelected: PropTypes.func.isRequired,
};

export default ImageCoordinatePicker;
