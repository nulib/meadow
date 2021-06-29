import React from "react";
import PropTypes from "prop-types";
import MediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import useTechnicalMetadata from "@js/hooks/useTechnicalMetadata";
import useFileSet from "@js/hooks/useFileSet";

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
  const { getTechnicalMetadata } = useTechnicalMetadata();
  const mediaInfoTracks = getTechnicalMetadata(fileSet);
  const { isEmpty } = useFileSet();
  if (isEmpty(fileSet)) return null;

  const sources = [
    {
      id: fileSet?.streamingUrl,
      type: mediaInfoTracks[1]["@type"],
      format: fileSet?.coreMetadata?.mimeType,
      height: mediaInfoTracks[1].Height,
      width: mediaInfoTracks[1].Width,
      duration: mediaInfoTracks[1].Duration,
    },
  ];

  return (
    <div>
      <MediaPlayer sources={sources} tracks={mockVideoTracks} />
    </div>
  );
}

MediaPlayerWrapper.propTypes = {
  fileSet: PropTypes.object,
};

export default MediaPlayerWrapper;
