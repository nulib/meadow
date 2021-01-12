import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

function UIFallbackErrorComponent({ error }) {
  return (
    <div
      role="alert"
      className="notification is-danger has-text-centered content"
    >
      <p>
        <FontAwesomeIcon icon="exclamation-triangle" /> There was an error
        rendering
      </p>
      <p>
        <strong>Error</strong>: {error.message}
      </p>
    </div>
  );
}

UIFallbackErrorComponent.propTypes = {
  error: PropTypes.object,
};

export default UIFallbackErrorComponent;
