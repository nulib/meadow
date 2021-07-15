import React from "react";
import PropTypes from "prop-types";
import MediaPlayerNav from "@js/components/UI/MediaPlayer/Nav";

function MediaPlayer({
  navCues = [],
  sources = [],
  tracks = [],
  videoElAttrs = {},
  ...restProps
}) {
  const playerRef = React.useRef();

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
        </video>
        <div className="block" className="column is-one-quarter">
          <h3>Video nav</h3>
          <MediaPlayerNav cues={navCues} handleNavClick={handleNavClick} />
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
