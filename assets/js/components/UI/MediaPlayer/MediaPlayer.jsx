import React from "react";
import PropTypes from "prop-types";
import MediaPlayerNav from "@js/components/UI/MediaPlayer/Nav";
import getVttFile from "@js/services/get-vtt-file";

function MediaPlayer({
  sources = [],
  tracks = [],
  videoElAttrs = {},
  ...restProps
}) {
  const playerRef = React.useRef();
  const [cues, setCues] = React.useState([]);

  React.useEffect(() => {
    if (tracks.length === 0) return;
    async function getVtt() {
      const parsed = await getVttFile(tracks[0].src);
      if (parsed) {
        setCues([...parsed.cues]);
      }
    }

    getVtt();
  }, [tracks]);

  const handleNavClick = (e, cue) => {
    e.preventDefault();
    if (!cue) return;
    playerRef.current.currentTime = cue?.start;
  };

  return (
    <>
      <div className="columns">
        <video
          data-testid="video-player"
          ref={playerRef}
          controls
          className="column is-three-quarters"
          {...videoElAttrs}
          {...restProps}
        >
          {sources.map(({ src, type }) => (
            <source key={src} data-testid="source-item" src={src} type={type} />
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
  tracks: PropTypes.array,
};

export default MediaPlayer;
