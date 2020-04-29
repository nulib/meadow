import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { setVisibilityClass } from "../../services/helpers";

const WorkCardItem = ({ work }) => {
  const fileSetsToDisplay = 5;

  return (
    <div className="card is-shadowless" data-testid="ui-workcard">
      <div className="card-image">
        <figure className="image is-4by3">
          <Link to={`/work/${work.id}`}>
            <img
              src={`${work.representativeImage}/full/1280,960/0/default.jpg`}
              data-testid="image-work"
              alt={work.title}
              onError={(e) => {
                e.target.src = "/images/1280x960.png";
              }}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content">
        <h3 className="title is-size-4">
          {work.accessionNumber} <span className="tag">{work.workType}</span>
          <span
            data-testid="tag-visibility"
            className={`tag ${setVisibilityClass(work.visibility)}`}
          >
            {work.visibility.toUpperCase()}
          </span>
        </h3>

        {/* <p className="subtitle is-size-6">Accession Number</p> */}
        <h4 className="subtitle">
          Filesets <span className="tag is-light">{work.fileSets.length}</span>
        </h4>
        <div className="list has-background-light">
          {work.fileSets &&
            work.fileSets.slice(0, fileSetsToDisplay - 1).map((fileSet, i) => (
              <span
                key={fileSet.id}
                className="list-item"
                data-testid={`fileset-${fileSet.id}`}
              >
                {fileSet.accessionNumber} -{" "}
                {fileSet.metadata &&
                  fileSet.metadata.description &&
                  fileSet.metadata.description}
              </span>
            ))}
        </div>
      </div>
    </div>
  );
};

WorkCardItem.propTypes = {
  work: PropTypes.object,
};

export default WorkCardItem;
