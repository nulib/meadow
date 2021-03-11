import React from "react";
import PropTypes from "prop-types";

function UIMeadowVersion({ showHoneyVersion }) {
  if (!__MEADOW_VERSION__) {
    return "v.dev";
  }

  return (
    <>
      <a
        href={`https://github.com/nulib/meadow/tree/${__MEADOW_VERSION__}`}
        target="_blank"
      >
        {__MEADOW_VERSION__}
      </a>{" "}
      {showHoneyVersion && (
        <a
          href={`https://github.com/nulib/meadow/commit/${__HONEYBADGER_REVISION__}`}
          target="_blank"
        >
          {__HONEYBADGER_REVISION__}
        </a>
      )}
    </>
  );
}

UIMeadowVersion.propTypes = {
  showHoneyVersion: PropTypes.bool,
};

export default UIMeadowVersion;
