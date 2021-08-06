import React from "react";
import PropTypes from "prop-types";
import MediaPlayerNav from "@js/components/UI/MediaPlayer/Nav";
import Hls from "hls.js";
import useEnvironment from "@js/hooks/useEnvironment";

const stagingUrl =
  "https://meadow-streaming.rdc-staging.library.northwestern.edu/85/bd/1f/cd/-5/ff/6-/45/fb/-a/c5/1-/e4/56/44/6d/cb/00/6298d09f04833eb737504941812b0442e6253a4e286e79db3b11e16f9b39c604.m3u8";

function MediaPlayer({ navCues = [], src, videoElAttrs = {}, ...restProps }) {
  const playerRef = React.useRef();
  const env = useEnvironment();
  let isDev = env === "DEV";

  // Mock out m3u8
  // src = stagingUrl;
  // isDev = false;

  /**
   * HLS.js binding for .m3u8 files
   * STAGING and PRODUCTION environments only
   */
  React.useEffect(() => {
    if (!src || isDev) return;

    // Bind hls.js package to our <video /> element
    // and then load the media source
    const hls = new Hls();
    hls.attachMedia(playerRef.current);
    hls.on(Hls.Events.MEDIA_ATTACHED, function () {
      hls.loadSource(src);
    });
    hls.on(Hls.Events.ERROR, function (event, data) {
      console.error(`data`, data);
    });
  }, [src]);

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
          {isDev && <source src={src} />}
        </video>
        <div className="column is-one-quarter content">
          <h5 className="is-size-6 has-text-light">Navigation</h5>
          <MediaPlayerNav cues={navCues} handleNavClick={handleNavClick} />
        </div>
      </div>
    </>
  );
}

MediaPlayer.propTypes = {
  navCues: PropTypes.array,
  src: PropTypes.string.isRequired,
  videoElAttrs: PropTypes.object,
  poster: PropTypes.string,
};

export default MediaPlayer;
