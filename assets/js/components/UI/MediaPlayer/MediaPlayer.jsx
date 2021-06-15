import React from "react";
import PropTypes from "prop-types";
import MediaPlayerNav from "@js/components/UI/MediaPlayer/Nav";
const webvtt = require("node-webvtt");
import { Notification } from "@nulib/admin-react-components";

const vttSampleUrl =
  "https://s3.amazonaws.com/demo.jwplayer.com/text-tracks/assets/chapters.vtt";

export const mockVideoSources = [
  {
    id: "http://dlib.indiana.edu/iiif_av/volleyball/high/volleyball-for-boys.mp4",
    type: "Video",
    format: "video/mp4",
    height: 1080,
    width: 1920,
    duration: 662.037,
    label: {
      "@none": ["high"],
    },
  },
  {
    id: "http://dlib.indiana.edu/iiif_av/volleyball/medium/volleyball-for-boys.mp4",
    type: "Video",
    format: "video/mp4",
    height: 1080,
    width: 1920,
    duration: 662.037,
    label: {
      "@none": ["medium"],
    },
  },
  {
    id: "http://dlib.indiana.edu/iiif_av/volleyball/low/volleyball-for-boys.mp4",
    type: "Video",
    format: "video/mp4",
    height: 1080,
    width: 1920,
    duration: 662.037,
    label: {
      "@none": ["low"],
    },
  },
];

export const mockVideoTracks = [
  {
    id: "nav",
    src: vttSampleUrl,
    kind: "chapters",
    label: "",
    srcLang: "en",
  },
];

function MediaPlayer({ sources = [], tracks = [], ...restProps }) {
  const playerRef = React.useRef();
  const [cues, setCues] = React.useState([]);

  React.useEffect(() => {
    async function getVttFile() {
      try {
        // Get network request VTT file
        const response = await fetch(tracks[0].src, {
          method: "GET",
          headers: {
            "Content-Type": "text/text; charset=utf-8",
          },
        });

        // Handle errors
        if (!response.ok) {
          throw new Error("Error grabbing VTT file");
        }

        // Parse contents and add cues to state
        const vttContents = await response.text();
        const parsed = webvtt.parse(vttContents);
        if (!parsed.valid) {
          throw new Error("Invalid VTT file");
        }
        setCues([...parsed.cues]);
      } catch (e) {
        console.error("Error loading and parsing VTT file");
      }
    }

    getVttFile();
  }, []);

  const handleNavClick = (e, cue) => {
    e.preventDefault();
    if (!cue) return;
    playerRef.current.currentTime = cue?.start;
  };

  return (
    <>
      <Notification isWarning isCentered>
        This is a hardcoded test video
      </Notification>
      <div className="columns">
        <video
          data-testid="video-player"
          crossOrigin="anonymous"
          ref={playerRef}
          className="column is-three-quarters"
          {...restProps}
        >
          {sources.map((source) => (
            <source
              key={source.id}
              data-testid="source-item"
              src={source.id}
              type={source.format}
            />
          ))}
          {tracks.map((track) => (
            <track
              key={track.id}
              id={track.identifier}
              data-testid="track"
              src={track.src}
              kind={track.kind}
              srcLang={track.srcLang}
            />
          ))}
        </video>
        <div className="block" className="column is-one-quarter">
          <h3>Video nav</h3>
          <MediaPlayerNav cues={cues} handleNavClick={handleNavClick} />
        </div>
      </div>
    </>
  );
}

MediaPlayer.propTypes = {
  sources: PropTypes.array,
};

export default MediaPlayer;
