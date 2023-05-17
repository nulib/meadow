import PropTypes from "prop-types";
import React from "react";
import { Tag } from "@nulib/design-system";

function UIVisibilityTag({ visibility, ...restProps }) {
  const isGraphQL = visibility.id;
  let label = "";
  let isDanger = false;
  let isPrimary = false;

  if (isGraphQL) {
    let id = visibility.id.toUpperCase();
    label = visibility.label;
    isDanger = id === "RESTRICTED";
    isPrimary = id === "AUTHENTICATED";
  } else if (typeof visibility === "string") {
    label = visibility;
    isDanger = visibility === "Private";
    isPrimary = visibility === "Institution";
  }

  return (
    <Tag isDanger={isDanger} isPrimary={isPrimary} {...restProps}>
      {label}
    </Tag>
  );
}

export default UIVisibilityTag;
