import React from "react";
import PropTypes from "prop-types";
import MediaPlayerNav from "@js/components/UI/MediaPlayer/Nav";
import Hls from "hls.js";

function MediaPlayer({
  navCues = [],
  sources = [],
  tracks = [],
  videoElAttrs = {},
  ...restProps
}) {
  const playerRef = React.useRef();

  React.useEffect(() => {
    if (sources.length === 0) return;

    console.log(`Hls.isSupported()`, Hls.isSupported());

    const video = playerRef.current;
    const url =
      "https://meadow-streaming.rdc-staging.library.northwestern.edu/85/bd/1f/cd/-5/ff/6-/45/fb/-a/c5/1-/e4/56/44/6d/cb/00/6298d09f04833eb737504941812b0442e6253a4e286e79db3b11e16f9b39c604.m3u8";
    const hls = new Hls();

    hls.attachMedia(playerRef.current);
    hls.on(Hls.Events.MEDIA_ATTACHED, function () {
      console.log("video and hls.js are now bound together !");
      hls.loadSource(url);
      hls.on(Hls.Events.MANIFEST_PARSED, function (event, data) {
        console.log(
          "manifest loaded, found " + data.levels.length + " quality level"
        );
      });
    });
    hls.on(Hls.Events.ERROR, function (event, data) {
      console.log(`data`, data);
      var errorType = data.type;
      var errorDetails = data.details;
      var errorFatal = data.fatal;
    });
  }, [sources]);

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
          {/* {sources.map(({ src, type }) => (
            <source key={src} data-testid="source-item" src={src} type={type} />
          ))} */}
          {/* <source
            src={`https://meadow-streaming.rdc-staging.library.northwestern.edu/85/bd/1f/cd/-5/ff/6-/45/fb/-a/c5/1-/e4/56/44/6d/cb/00/6298d09f04833eb737504941812b0442e6253a4e286e79db3b11e16f9b39c604.m3u8`}
          /> */}
        </video>
        <div className="block" className="column is-one-quarter">
          <h3>Video nav</h3>
          <MediaPlayerNav cues={navCues} handleNavClick={handleNavClick} />
        </div>
      </div>
      <div>
        <video
          width="600"
          controls
          height="400"
          src="https://meadow-streaming.rdc-staging.library.northwestern.edu/85/bd/1f/cd/-5/ff/6-/45/fb/-a/c5/1-/e4/56/44/6d/cb/00/6298d09f04833eb737504941812b0442e6253a4e286e79db3b11e16f9b39c604.m3u8"
        />
      </div>
    </>
  );
}

MediaPlayer.propTypes = {
  sources: PropTypes.array,
  tracks: PropTypes.array,
};

export default MediaPlayer;
