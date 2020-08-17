import React, { useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { setVisibilityClass, formatDate } from "../../services/helpers";

const WorkCardItem = ({
  id,
  representativeImage,
  title,
  workType,
  visibility,
  published,
  collectionName,
}) => {
  return (
    <div className="card " data-testid="ui-workcard">
      <div className="card-image">
        <figure className="image is-3by3">
          <Link to={`/work/${id}`}>
            <img
              src={
                representativeImage.fileSetId
                  ? `${representativeImage.url}/square/500,500/0/default.jpg`
                  : `${representativeImage}/full/1280,960/0/default.jpg`
              }
              data-testid="image-work"
              alt={title}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content">
        <h2
          className="subtitle"
          dangerouslySetInnerHTML={{
            __html: title ? title : "Untitled",
          }}
        ></h2>
        {collectionName && <strong>{collectionName}</strong>}
        <div className="content">
          <p>
            <span className="tag">{workType.label.toUpperCase()}</span>{" "}
            {visibility && (
              <span
                data-testid="tag-visibility"
                className={`tag ${setVisibilityClass(visibility.id)}`}
              >
                {visibility.label.toUpperCase()}
              </span>
            )}{" "}
            {published && (
              <span
                data-testid="result-item-published"
                className="tag is-success"
              >
                PUBLISHED
              </span>
            )}
          </p>
        </div>
      </div>
    </div>
  );
};

WorkCardItem.propTypes = {
  work: PropTypes.object,
};

export default WorkCardItem;
