import React from "react";
import PropTypes from "prop-types";
import MediaPlayerPosterSelector from "@js/components/UI/MediaPlayer/PosterSelector";
import ReactMediaPlayer from "@nulib/react-media-player";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

function MediaPlayerWrapper({ fileSets, manifestId }) {
  const workState = useWorkState();
  const dispatch = useWorkDispatch();

  const handleCanvasIdCallback = (canvasId) => {
    if (canvasId !== "")
      dispatch({
        type: "updateActiveMediaFileSet",
        fileSet: fileSets.find(
          (fileSet) => fileSet.id === canvasId.split("/").pop()
        ),
      });
    return;
  };

  if (!workState.activeMediaFileSet) return <></>;

  return (
    <div className="container">
      <ReactMediaPlayer
        manifestId={manifestId}
        canvasIdCallback={handleCanvasIdCallback}
      />
      {workState.activeMediaFileSet?.id && <MediaPlayerPosterSelector />}
    </div>
  );
}

MediaPlayerWrapper.propTypes = {
  fileSets: PropTypes.array,
  manifestId: PropTypes.string,
};

export default MediaPlayerWrapper;
