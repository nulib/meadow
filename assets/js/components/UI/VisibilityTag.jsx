import React from "react";
import PropTypes from "prop-types";
import { Tag } from "@nulib/design-system";

function UIVisibilityTag({ visibility, ...restProps }) {
  if (!visibility.id || !visibility.label) return null;
  let id = visibility.id.toUpperCase();

  return (
    <Tag
      isDanger={id === "RESTRICTED"}
      isPrimary={id === "AUTHENTICATED"}
      {...restProps}
    >
      {visibility.label}
    </Tag>
  );
}

UIVisibilityTag.propTypes = {
  visibility: PropTypes.object,
};

export default UIVisibilityTag;
