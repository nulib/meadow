import React, { useContext } from "react";
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
  accessionNumber,
  fileSets,
  manifestUrl,
  updatedAt,
}) => {
  return (
    <div className="card " data-testid="ui-workcard">
      <div className="card-image">
        <figure className="image is-4by3">
          <Link to={`/work/${id}`}>
            <img
              src={`${
                representativeImage.id
                  ? representativeImage.url + "/square/500,500/0/default.jpg"
                  : representativeImage + "/full/1280,960/0/default.jpg"
              }`}
              data-testid="image-work"
              alt={title}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content">
        <h3 className="title is-size-4">{title ? title : "Untitled"}</h3>

        <div className="content">
          <p>
            <span className="tag">{workType.label.toUpperCase()}</span>
            {visibility && (
              <span
                data-testid="tag-visibility"
                className={`tag ${setVisibilityClass(visibility.id)}`}
              >
                {visibility.label.toUpperCase()}
              </span>
            )}
            {published && (
              <span
                data-testid="result-item-published"
                className="tag is-success"
              >
                PUBLISHED
              </span>
            )}
          </p>
          <dl>
            <dt>Accession Number:</dt>
            <dd data-testid="result-item-accession-number">
              {accessionNumber}
            </dd>
            <dt>Filesets:</dt>
            <dd>
              <span
                className="tag is-light"
                data-testid="result-item-filesets-length"
              >
                {fileSets}
              </span>
            </dd>
            <dt>Last Updated: </dt>
            <dd data-testid="result-item-updated-date">
              {formatDate(updatedAt)}
            </dd>
            <dt>IIIF Manifest:</dt>
            <dd>
              <a href={manifestUrl} target="_blank">
                <u>JSON File</u>
              </a>
            </dd>
          </dl>
        </div>
      </div>
    </div>
  );
};

WorkCardItem.propTypes = {
  work: PropTypes.object,
};

export default WorkCardItem;
