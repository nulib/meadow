import React from "react";
import PropTypes from "prop-types";

function UIMessage({ children, ...restProps }) {
  return (
    <div className="message content block is-dark mx-3" {...restProps}>
      <div className="message-body">{children}</div>
    </div>
  );
}

UIMessage.propTypes = {};

export default UIMessage;
