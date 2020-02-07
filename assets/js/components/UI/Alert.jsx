import React from "react";
import PropTypes from "prop-types";

const UIAlert = ({
  title = "You should include a title",
  body = "You should probably have a message body",
  type = "info"
}) => {
  return (
    <div data-testid="ui-alert" className={`alert my-4 ${type}`} role="alert">
      <div className="flex">
        <div className="py-1">
          {type === "success" && "success checkmark icon here"}
          {type !== "success" && "info icon here"}
        </div>
        <div>
          <p className="font-bold">{title}</p>
          <div className="text-sm">{body}</div>
        </div>
      </div>
    </div>
  );
};

UIAlert.propTypes = {
  title: PropTypes.string.isRequired,
  body: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
  type: PropTypes.oneOf(["info", "danger", "success"])
};

export default UIAlert;
