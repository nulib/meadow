import React, { useCallback, useEffect, useRef, useState } from "react";
import PropTypes from "prop-types";
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
  const openseadragonRef = useRef(null);
  const interactiveRef = useRef(interactive);
  const onPointSelectedRef = useRef(onPointSelected);
  const hasRefreshedInitialTileRef = useRef(false);
  const [viewerReady, setViewerReady] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isPanning, setIsPanning] = useState(false);
  const activeCursor = isPanning
    ? "grabbing"
    : interactive
      ? "crosshair"
      : "grab";

  useEffect(() => {
    interactiveRef.current = interactive;
  }, [interactive]);

  useEffect(() => {
    onPointSelectedRef.current = onPointSelected;
  }, [onPointSelected]);

  const refreshViewer = () => {
    const viewer = viewerRef.current;
    if (!viewer) return;

    viewer.forceResize();
    viewer.viewport?.applyConstraints();
    viewer.forceRedraw?.();
  };

  const queueViewerRefresh = () => {
    window.requestAnimationFrame(() => {
      refreshViewer();
      window.requestAnimationFrame(refreshViewer);
    });
    window.setTimeout(refreshViewer, 0);
    window.setTimeout(refreshViewer, 100);
    window.setTimeout(refreshViewer, 300);
  };

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

  useEffect(() => {
    let isMounted = true;

    async function initializeViewer() {
      if (!containerRef.current || !imageServiceUrl) return;

      const module = await import("openseadragon");
      if (!isMounted) return;

      const OpenSeadragon = module.default || module;
      openseadragonRef.current = OpenSeadragon;

      viewerRef.current?.destroy();
      hasRefreshedInitialTileRef.current = false;
      viewerRef.current = OpenSeadragon({
        element: containerRef.current,
        tileSources: `${imageServiceUrl.replace(/\/$/, "")}/info.json`,
        immediateRender: true,
        showNavigationControl: false,
        showNavigator: true,
        gestureSettingsMouse: {
          clickToZoom: false,
          dragToPan: true,
        },
        gestureSettingsPen: {
          clickToZoom: false,
          dragToPan: true,
        },
        gestureSettingsTouch: {
          clickToZoom: false,
          dragToPan: true,
        },
      });

      viewerRef.current.addHandler("canvas-click", (event) => {
        if (!interactiveRef.current) return;
        if (event.quick === false) return;

        event.preventDefaultAction = true;
        const viewportPoint = viewerRef.current.viewport.pointFromPixel(
          event.position,
        );
        const imagePoint =
          viewerRef.current.viewport.viewportToImageCoordinates(viewportPoint);

        onPointSelectedRef.current([
          Number(imagePoint.x.toFixed(2)),
          Number(imagePoint.y.toFixed(2)),
        ]);
      });

      viewerRef.current.addHandler("canvas-drag", () => setIsPanning(true));
      viewerRef.current.addHandler("canvas-drag-end", () =>
        setIsPanning(false),
      );
      viewerRef.current.addHandler("canvas-release", () => setIsPanning(false));
      viewerRef.current.addHandler("canvas-exit", () => setIsPanning(false));

      viewerRef.current.addHandler("open", () => {
        setViewerReady(true);
        viewerRef.current?.viewport.goHome(true);
        queueViewerRefresh();
        const item = viewerRef.current.world.getItemAt(0);
        const size = item?.getContentSize?.();
        if (size?.x && size?.y) {
          onDimensions({
            width: Math.round(size.x),
            height: Math.round(size.y),
          });
        }
      });

      viewerRef.current.addHandler("tile-loaded", () => {
        if (hasRefreshedInitialTileRef.current) return;
        hasRefreshedInitialTileRef.current = true;
        queueViewerRefresh();
      });
    }

    initializeViewer();

    return () => {
      isMounted = false;
      setViewerReady(false);
      setIsPanning(false);
      viewerRef.current?.destroy();
      viewerRef.current = null;
    };
  }, [imageServiceUrl, interactive, onDimensions]);

  useEffect(() => {
    if (!shellRef.current || typeof ResizeObserver === "undefined") return;

    const resizeObserver = new ResizeObserver(queueViewerRefresh);
    resizeObserver.observe(shellRef.current);

    return () => resizeObserver.disconnect();
  }, []);

  useEffect(() => {
    const handleFullscreenChange = () => {
      const isViewerFullscreen =
        document.fullscreenElement === shellRef.current;
      setIsFullscreen(isViewerFullscreen);
      queueViewerRefresh();
    };

    document.addEventListener("fullscreenchange", handleFullscreenChange);
    return () =>
      document.removeEventListener("fullscreenchange", handleFullscreenChange);
  }, []);

  useEffect(() => {
    const viewer = viewerRef.current;
    const OpenSeadragon = openseadragonRef.current;
    if (!viewer || !OpenSeadragon || !viewerReady) return;

    viewer.clearOverlays();

    imagePoints.forEach((point, index) => {
      if (!point?.coords?.length) return;

      const marker = document.createElement("div");
      marker.className = `georeference-image-point${
        point.isPending ? " is-pending" : ""
      }`;
      marker.textContent = point.label || index + 1;

      viewer.addOverlay({
        element: marker,
        location: viewer.viewport.imageToViewportCoordinates(
          new OpenSeadragon.Point(point.coords[0], point.coords[1]),
        ),
        placement: OpenSeadragon.Placement.CENTER,
        checkResize: false,
      });
    });
  }, [imagePoints, viewerReady]);

  const zoomBy = (factor) => {
    const viewer = viewerRef.current;
    if (!viewer) return;

    viewer.viewport.zoomBy(factor);
    viewer.viewport.applyConstraints();
  };

  const goHome = () => {
    viewerRef.current?.viewport.goHome();
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
        className="georeference-image-actions"
        aria-label="Image controls"
        style={{
          display: "flex",
          position: "absolute",
          right: "0.5rem",
          top: "0.5rem",
          zIndex: 2,
        }}
      >
        <button
          type="button"
          className="button is-small"
          aria-label="Zoom in"
          title="Zoom in"
          onClick={() => zoomBy(1.2)}
          style={{ borderRadius: 0 }}
        >
          <FiZoomIn aria-hidden />
        </button>
        <button
          type="button"
          className="button is-small"
          aria-label="Zoom out"
          title="Zoom out"
          onClick={() => zoomBy(0.8)}
          style={{ borderRadius: 0 }}
        >
          <FiZoomOut aria-hidden />
        </button>
        <button
          type="button"
          className="button is-small"
          aria-label="Reset view"
          title="Reset view"
          onClick={goHome}
          style={{ borderRadius: 0 }}
        >
          <FiHome aria-hidden />
        </button>
        <button
          type="button"
          className="button is-small"
          aria-label={isFullscreen ? "Exit fullscreen" : "Enter fullscreen"}
          title={isFullscreen ? "Exit fullscreen" : "Enter fullscreen"}
          onClick={toggleFullscreen}
          style={{ borderRadius: 0 }}
        >
          {isFullscreen ? (
            <FiMinimize aria-hidden />
          ) : (
            <FiMaximize aria-hidden />
          )}
        </button>
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
          width: "100%",
        }}
      />
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
