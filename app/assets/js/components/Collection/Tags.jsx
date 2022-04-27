import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";
import { Tag } from "@nulib/design-system";

function CollectionTags({ collection }) {
  const { featured, published, visibility } = collection;

  return (
    <div className="mb-4 tags">
      <Tag
        data-testid="published-tag"
        isWarning={!published}
        isSuccess={published}
      >
        {published ? "Published" : "Not Published"}
      </Tag>
      {visibility && (
        <Tag
          isDanger={visibility.id === "RESTRICTED"}
          isPrimary={visibility.id === "AUTHENTICATED"}
        >
          {visibility.label}
        </Tag>
      )}
      {featured && <Tag>Featured</Tag>}
    </div>
  );
}

CollectionTags.propTypes = {
  collection: PropTypes.object,
};

export default CollectionTags;
