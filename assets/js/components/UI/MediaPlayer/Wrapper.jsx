import React, { useState } from "react";
import PropTypes from "prop-types";
import MediaPlayerPosterSelector from "@js/components/UI/MediaPlayer/PosterSelector";
import ReactMediaPlayer from "@nulib/react-media-player";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

const MediaPlayerWrapper = ({ fileSets, manifestId, canvasReady = false }) => {
  const workState = useWorkState();
  const dispatch = useWorkDispatch();

  const { activeMediaFileSet, workTypeId } = workState;
  const [isCanvasReady, setIsCanvasReady] = useState(canvasReady);

  const handleCanvasIdCallback = (canvasId) => {
    if (canvasId !== "") {
      setIsCanvasReady(true);
      dispatch({
        type: "updateActiveMediaFileSet",
        fileSet: fileSets.find(
          (fileSet) => fileSet.id === canvasId.split("/").pop()
        ),
      });
    }
    return;
  };

  return (
    <div className="container" data-testid="media-player-wrapper">
      <ReactMediaPlayer
        manifestId={manifestId}
        canvasIdCallback={handleCanvasIdCallback}
      />
      {isCanvasReady && workTypeId !== "AUDIO" && activeMediaFileSet?.id && (
        <MediaPlayerPosterSelector />
      )}
    </div>
  );
};

MediaPlayerWrapper.propTypes = {
  fileSets: PropTypes.array,
  manifestId: PropTypes.string,
};

export default MediaPlayerWrapper;
