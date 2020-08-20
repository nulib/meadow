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
          <Link to={`/work/${id}`} className="hvr-shrink">
            <img
              src={
                representativeImage.fileSetId
                  ? `${representativeImage.url}/square/500,500/0/default.jpg`
                  : `${
                      representativeImage
                        ? `${representativeImage}/full/1280,960/0/default.jpg`
                        : "/images/480x480.png"
                    }`
              }
              data-testid={`work-image-${id}`}
              alt={title}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content content">
        <p data-testid={`work-title-${id}`}>{title}</p>

        {collectionName && <p className="heading">{collectionName}</p>}

        <p className="has-text-uppercase">
          {workType && <span className="tag">{workType.label}</span>}{" "}
          {visibility && (
            <span
              data-testid="tag-visibility"
              className={`tag ${setVisibilityClass(visibility.id)}`}
            >
              {visibility.label}
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
  );
};

WorkCardItem.propTypes = {
  work: PropTypes.object,
};

export default WorkCardItem;
