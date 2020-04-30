import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { setVisibilityClass, formatDate } from "../../services/helpers";

const WorkCardItem = ({ work }) => {
  return (
    <div className="card is-shadowless" data-testid="ui-workcard">
      <div className="card-image">
        <figure className="image is-4by3">
          <Link to={`/work/${work.id}`}>
            <img
              src={`${
                work.representativeImage
                  ? work.representativeImage + "/full/1280,960/0/default.jpg"
                  : "/images/1280x960.png"
              }`}
              data-testid="image-work"
              alt={work.title}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content">
        <h3 className="title is-size-4">
          {work.descriptiveMetadata.title
            ? work.descriptiveMetadata.title
            : "Untitled"}
        </h3>

        <div className="content">
          <p>
            <span className="tag">{work.workType}</span>
            <span
              data-testid="tag-visibility"
              className={`tag ${setVisibilityClass(work.visibility)}`}
            >
              {work.visibility.toUpperCase()}
            </span>
          </p>
          <dl>
            <dt>Accession Number:</dt>
            <dd data-testid="dd-accession-number">{work.accessionNumber}</dd>
            <dt>Filesets:</dt>
            <dd>
              <span className="tag is-light" data-testid="dd-filesets-length">
                {work.fileSets.length}
              </span>
            </dd>
            <dt>Last Updated: </dt>
            <dd data-testid="dd-updated-date">{formatDate(work.updatedAt)}</dd>
            <dt>IIIF Manifest:</dt>
            <dd>
              <a href={work.manifestUrl} target="_blank">
                <u>JSON File</u>
              </a>
            </dd>
            <dt>Published:</dt>
            <dd>
              <span data-testid="dd-published" className="tag">
                {work.published ? "True" : "False"}
              </span>
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
