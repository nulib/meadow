import React from "react";
import PropTypes from "prop-types";
import MediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import useTechnicalMetadata from "@js/hooks/useTechnicalMetadata";
import useFileSet from "@js/hooks/useFileSet";
import { Notification } from "@nulib/admin-react-components";
import UIIconText from "@js/components/UI/IconText";
import { IconAlert } from "@js/components/Icon";

const vttSampleUrl =
  "https://s3.amazonaws.com/demo.jwplayer.com/text-tracks/assets/chapters.vtt";

/* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track */
export const mockVideoTracks = [
  {
    id: "nav",
    src: vttSampleUrl,
    kind: "chapters",
    label: "",
    srcLang: "en",
  },
];

function MediaPlayerWrapper({ fileSet }) {
  const { isEmpty } = useFileSet();
  if (isEmpty(fileSet)) return null;

  const { getTechnicalMetadata } = useTechnicalMetadata();
  const mediaInfoTracks = getTechnicalMetadata(fileSet);

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

  return (
    <div>
      <MediaPlayer
        key={fileSet.id}
        sources={sources}
        tracks={mockVideoTracks}
        videoElAttrs={videoElAttrs}
      />
    </div>
  );
}

MediaPlayerWrapper.propTypes = {
  fileSet: PropTypes.object,
};

export default MediaPlayerWrapper;
