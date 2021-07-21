import React from "react";
import PropTypes from "prop-types";

function MediaPlayerNav({ cues = [], handleNavClick }) {
  return (
    <ul>
      {cues.map((cue) => (
        <li key={cue.start}>
          <a href="#" onClick={(e) => handleNavClick(e, cue)}>
            {cue.text} - ({cue.start} - {cue.end}s)
          </a>
        </li>
      ))}
    </ul>
  );
}

MediaPlayerNav.propTypes = {
  cues: PropTypes.array,
  handleNavClick: PropTypes.func,
};

export default MediaPlayerNav;
