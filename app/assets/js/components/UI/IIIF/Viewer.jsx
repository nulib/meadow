import React, { useEffect, useState } from "react";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

import CloverViewer from "@samvera/clover-iiif/viewer";
import IIIFViewerPosterSelector from "@js/components/UI/IIIF/PosterSelector";
import PropTypes from "prop-types";
import { getApiResponseHeaders } from "@js/services/get-api-response-headers";

const IIIFViewer = ({ fileSets, iiifContent, workTypeId }) => {
  const workState = useWorkState();
  const dispatch = useWorkDispatch();

  const { activeMediaFileSet, dcApiToken } = workState;
  const [etag, setEtag] = useState();

  /**
   * Get the etag from the API response headers every 10 seconds.
   */
  useEffect(() => {
    if (!dcApiToken) return;

    const fetchEtag = async () => {
      const response = await getApiResponseHeaders(iiifContent, dcApiToken);
      const headers = new Headers(response);
      const etag = headers.get("etag");
      setEtag(etag);
    };

    fetchEtag();

    const interval = setInterval(() => {
      fetchEtag();
    }, 10000);

    return () => clearInterval(interval);
  }, [dcApiToken, iiifContent]);

  /**
   * When the Canvas changed in Clover, update the active media file set in Context.
   */
  const handleCanvasIdCallback = (canvasId) => {
    if (canvasId) {
      const canvasIndex = canvasId.split("/").pop();
      if (fileSets[canvasIndex]?.id === activeMediaFileSet?.id) return;

      dispatch({
        type: "updateActiveMediaFileSet",
        fileSet: fileSets[canvasIndex],
      });
    }
    return;
  };

  const customTheme = {
    colors: {
      accent: "#4E2A84",
      accentAlt: "#401f68",
      accentMuted: "#B6ACD1",
      primary: "#000000",
      primaryAlt: "#342F2E",
      primaryMuted: "#716C6B",
      secondary: "#FFFFFF",
      secondaryAlt: "#D8D6D6",
      secondaryMuted: "#F0F0F0",
    },
  };

  const options = {
    canvasHeight: 480,
    informationPanel: {
      open: false,
    },
    openSeadragon: {
      gestureSettingsMouse: {
        scrollToZoom: false,
      },
    },
    requestHeaders: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${dcApiToken}`,
    },
    showIIIFBadge: false,
  };

  if (!dcApiToken) return <></>;

  return (
    <div className="container iiif-viewer" data-testid="iiif-viewer">
      <CloverViewer
        canvasIdCallback={handleCanvasIdCallback}
        customTheme={customTheme}
        iiifContent={iiifContent}
        key={etag}
        options={options}
      />
      {workTypeId === "VIDEO" && activeMediaFileSet?.id && (
        <IIIFViewerPosterSelector />
      )}
    </div>
  );
};

IIIFViewer.propTypes = {
  fileSet: PropTypes.object,
  fileSets: PropTypes.array,
  iiifContent: PropTypes.string,
  workTypeId: PropTypes.oneOf(["AUDIO", "VIDEO", "IMAGE"]),
};

export default IIIFViewer;
