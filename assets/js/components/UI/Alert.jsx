import React from "react";
import PropTypes from "prop-types";

const UIAlert = ({
  title = "You should include a title",
  body = "You should probably have a message body",
  type = "is-info",
}) => {
  return (
    <article data-testid="ui-alert" className={`message ${type}`}>
      <div className="message-header">
        <p>{title}</p>
      </div>
      <div className="message-body">{body}</div>
    </article>
  );
};

UIAlert.propTypes = {
  title: PropTypes.string.isRequired,
  body: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
  type: PropTypes.oneOf(["is-info", "is-danger", "is-success"]),
};

export default UIAlert;
