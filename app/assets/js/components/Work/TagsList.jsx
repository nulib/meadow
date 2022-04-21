import React from "react";
import PropTypes from "prop-types";
import { Icon, Tag } from "@nulib/design-system";
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
        <Icon>
          {id === "AUDIO" && <Icon.Audio />}
          {id === "IMAGE" && <Icon.Image />}
          {id === "VIDEO" && <Icon.Video />}
        </Icon>
        <span>{work.workType.label}</span>
      </>
    );
  }

  return (
    <div className="tags">
      {work.workType && (
        <Tag isInfo isIcon>
          {renderWorkType()}
        </Tag>
      )}
      {work.published ? (
        <Tag isSuccess>Published</Tag>
      ) : (
        <Tag isWarning>Not Published</Tag>
      )}
      {work.visibility && <UIVisibilityTag visibility={work.visibility} />}
    </div>
  );
}

WorkTagsList.propTypes = {
  work: PropTypes.object,
};
