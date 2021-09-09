import React from "react";
import PropTypes from "prop-types";
import MediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import useTechnicalMetadata from "@js/hooks/useTechnicalMetadata";
import useFileSet from "@js/hooks/useFileSet";
import { Notification } from "@nulib/admin-react-components";
import UIIconText from "@js/components/UI/IconText";
import { IconAlert } from "@js/components/Icon";
const webvtt = require("node-webvtt");
import MediaPlayerPosterSelector from "@js/components/UI/MediaPlayer/PosterSelector";
import MediaPlayerSwitcher from "@js/components/UI/MediaPlayer/Switcher";

function MediaPlayerWrapper({ fileSet, fileSets }) {
  const { getWebVttString, isEmpty } = useFileSet();
  if (isEmpty(fileSet)) return null;

  const { getTechnicalMetadata } = useTechnicalMetadata();
  const mediaInfoTracks = getTechnicalMetadata(fileSet);
  const webVttString = getWebVttString(fileSet);
  let navCues;

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

  return (
    <>
      <div className="has-background-grey-lighter py-3">
        <div className="container block">
          <MediaPlayerSwitcher fileSets={fileSets} />
        </div>
      </div>

      <section className="section hero is-black">
        <div className="container">
          <div>
            <MediaPlayer
              key={fileSet.id}
              navCues={navCues}
              src={fileSet?.streamingUrl}
              poster={
                fileSet?.representativeImageUrl
                  ? `${fileSet?.representativeImageUrl}/full/1200,/0/default.jpg`
                  : `/images/video-placeholder2.png`
              }
              videoElAttrs={videoElAttrs}
            />
          </div>
          <MediaPlayerPosterSelector />
        </div>
      </section>
    </>
  );
}

MediaPlayerWrapper.propTypes = {
  fileSet: PropTypes.object,
  fileSets: PropTypes.array,
};

export default MediaPlayerWrapper;
