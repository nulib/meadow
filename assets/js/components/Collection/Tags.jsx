import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";

function CollectionTags({ collection }) {
  const { featured, published, visibility } = collection;

  return (
    <div className="mb-4">
      <span
        data-testid="published-tag"
        className={classNames("tag", "mr-1", "is-light", {
          "is-warning": !published,
          "is-success": published,
        })}
      >
        {published ? "Published" : "Not Published"}
      </span>
      {visibility && (
        <span
          className={classNames("tag", "is-light", "mr-1", {
            "is-danger": visibility.id === "RESTRICTED",
            "is-info": visibility.id === "AUTHENTICATED",
          })}
        >
          {visibility.label}
        </span>
      )}
      {featured && (
        <span className={`tag is-info is-light mr-1`}>Featured</span>
      )}
    </div>
  );
}

CollectionTags.propTypes = {
  collection: PropTypes.object,
};

export default CollectionTags;
