import React from "react";
import PropTypes from "prop-types";
import { Tag } from "@nulib/admin-react-components";
import UIVisibilityTag from "@js/components/UI/VisibilityTag";
import { IconAudio, IconImages, IconVideo } from "../Icon";

export default function WorkTagsList({ work }) {
  if (!work) {
    return null;
  }

  function renderWorkType() {
    const id = work.workType.id;
    return (
      <>
        <span className="icon">
          {id === "AUDIO" && <IconAudio />}
          {id === "VIDEO" && <IconVideo />}
          {id === "IMAGE" && <IconImages />}
        </span>
        <span>{work.workType.label}</span>
      </>
    );
  }

  return (
    <p className="tags">
      {work.workType && <Tag isInfo>{renderWorkType()}</Tag>}
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
