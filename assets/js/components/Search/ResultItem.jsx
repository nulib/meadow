import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { buildImageURL } from "../../services/helpers";

const setVisibilityClass = visibility => {
  if (visibility.toUpperCase() === "RESTRICTED") {
    return "is-danger";
  }
  if (visibility.toUpperCase() === "OPEN") {
    return "is-success";
  }
  return "";
};

const SearchResultItem = ({ res }) => {
  const {
    _id,
    accession_number,
    file_sets = [],
    model,
    published,
    title,
    visibility
  } = res;
  const fileSetsToDisplay = 5;

  return (
    <div className="card">
      <div className="card-image">
        <figure className="image is-square">
          {file_sets.length > 0 && (
            <Link to={`/work/${_id}`}>
              <img
                src={`${buildImageURL(file_sets[0].id, "IIIF_SQUARE")}`}
                alt="Placeholder image"
              />
            </Link>
          )}
        </figure>
      </div>
      <div className="card-content">
        <h3 className="title is-size-4">
          {accession_number} <span className="tag">{model.name}</span>
        </h3>
        <p className="subtitle is-size-6">Accession Number</p>
        <h4 className="subtitle">
          Filesets{" "}
          <span className="tag is-link is-light">{file_sets.length}</span>
        </h4>
        <div className="list is-hoverable">
          {file_sets.map((fileSet, i) =>
            i < fileSetsToDisplay - 1 ? (
              <a key={fileSet.id} className="list-item">
                {fileSet.label}
              </a>
            ) : null
          )}
        </div>
        <p>
          <span className={`tag ${setVisibilityClass(visibility)}`}>
            {visibility}
          </span>
        </p>
      </div>
    </div>
  );
};

SearchResultItem.propTypes = {
  work: PropTypes.object
};

export default SearchResultItem;
