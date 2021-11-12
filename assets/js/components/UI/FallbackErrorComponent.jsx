import React from "react";
import PropTypes from "prop-types";
import { IconAlert } from "@js/components/Icon";
import { Notification } from "@nulib/design-system";

function UIFallbackErrorComponent({ error }) {
  return (
    <Notification isDanger isCentered role="alert" className="content">
      <p>
        <IconAlert /> There was an error rendering
      </p>
      <p>
        <strong>Error</strong>: {error.message}
      </p>
    </Notification>
  );
}

UIFallbackErrorComponent.propTypes = {
  error: PropTypes.object,
};

export default UIFallbackErrorComponent;
