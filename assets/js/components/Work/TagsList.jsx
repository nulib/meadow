import React from "react";
import PropTypes from "prop-types";
import { Tag } from "@nulib/admin-react-components";
import UIVisibilityTag from "@js/components/UI/VisibilityTag";

export default function WorkTagsList({ work }) {
  if (!work) {
    return null;
  }
  return (
    <p className="tags">
      {work.workType && <Tag isInfo>{work.workType.label}</Tag>}
      {work.published ? (
        <Tag isSuccess>Published</Tag>
      ) : (
        <Tag isWarning>Not Published</Tag>
      )}
      {work.visibility && <UIVisibilityTag visibility={work.visibility} />}
    </p>
  );
}

WorkTagsList.propTypes = {
  work: PropTypes.object,
};
