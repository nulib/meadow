import React from "react";
import PropTypes from "prop-types";
import MediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import useTechnicalMetadata from "@js/hooks/useTechnicalMetadata";
import useFileSet from "@js/hooks/useFileSet";
import { Notification } from "@nulib/admin-react-components";
import UIIconText from "@js/components/UI/IconText";
import { IconAlert } from "@js/components/Icon";
const webvtt = require("node-webvtt");
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

function MediaPlayerWrapper({ fileSet, fileSets }) {
  const { getWebVttString, isEmpty } = useFileSet();
  if (isEmpty(fileSet)) return null;

  const { getTechnicalMetadata } = useTechnicalMetadata();
  const mediaInfoTracks = getTechnicalMetadata(fileSet);
  const webVttString = getWebVttString(fileSet);
  let navCues;
  const workState = useWorkState();
  const dispatch = useWorkDispatch();

  // FileSet hasn't yet been fully ran through the pipeline
  if (!fileSet?.coreMetadata?.mimeType) {
    return (
      <Notification isWarning>
        <UIIconText isCentered icon={<IconAlert />}>
          The media file is being processed. Click refresh your browser in a few
          seconds
        </UIIconText>
      </Notification>
    );
  }

  const sources = [
    {
      src: fileSet?.streamingUrl,
    },
  ];
  const videoElAttrs = mediaInfoTracks &&
    mediaInfoTracks[1] && {
      height: mediaInfoTracks[1].Height,
      width: mediaInfoTracks[1].Width,
    };

  try {
    if (webVttString) {
      const parsed = webvtt.parse(webVttString);
      if (parsed.valid) {
        navCues = parsed.cues;
      }
    }
  } catch (e) {
    console.error(
      "Error parsing webvtt preparing nav cues for the MediaPlayer",
      e
    );
  }

  const handleSelectChange = (e) => {
    dispatch({
      type: "updateActiveMediaFileSet",
      fileSet: fileSets.find((fs) => fs.id === e.target.value),
    });
  };

  return (
    <>
      <div>
        <MediaPlayer
          key={fileSet.id}
          navCues={navCues}
          sources={sources}
          videoElAttrs={videoElAttrs}
        />
      </div>
      <div className="block content mt-4">
        <p>
          <strong>Select media:</strong>
        </p>
        <div className="select">
          <select
            value={workState?.activeMediaFileSet?.id}
            onChange={handleSelectChange}
          >
            {fileSets.map((option) => (
              <option key={option.id} value={option.id}>
                {option.coreMetadata?.label}
              </option>
            ))}
          </select>
        </div>
      </div>
    </>
  );
}

MediaPlayerWrapper.propTypes = {
  fileSet: PropTypes.object,
  fileSets: PropTypes.array,
};

export default MediaPlayerWrapper;
