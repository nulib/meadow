import React from "react";
import PropTypes from "prop-types";

const setVisibilityClass = visibility => {
  if (visibility.toUpperCase() === "RESTRICTED") {
    return "is-danger";
  }
  if (visibility.toUpperCase() === "OPEN") {
    return "is-success";
  }
  return "";
};

const SearchResultItem = ({ work }) => {
  const {
    _id,
    accession_number,
    description,
    model,
    published,
    title,
    visibility
  } = work;
  const fileSetsToDisplay = 5;
  // const imageIdToDisplay =
  //   work.fileSets && work.fileSets.length > 0 ? work.fileSets[0].id : "";

  return (
    <div className="card">
      <div className="card-image">
        <figure className="image is-4by3">
          {/* <Link to={`/work/${_id}`}>
            <img
              src={`${buildImageURL(imageIdToDisplay, "IIIF_SQUARE")}`}
              alt="Placeholder image"
              onError={e => {
                e.target.src = "/images/1280x960.png";
              }}
            />
          </Link> */}
        </figure>
      </div>
      <div className="card-content">
        <h3 className="title is-size-4">
          {accession_number} <span className="tag">{model.name}</span>
        </h3>
        <p className="subtitle is-size-6">Accession Number</p>
        <h4 className="subtitle">
          Filesets{" "}
          {/* <span className="tag is-link is-light">{work.fileSets.length}</span> */}
        </h4>
        {/* <div className="list is-hoverable">
          {work.fileSets.map((fileSet, i) =>
            i < fileSetsToDisplay - 1 ? (
              <a key={fileSet.id} className="list-item">
                {fileSet.accessionNumber} -{" "}
                {fileSet.metadata &&
                  fileSet.metadata.description &&
                  fileSet.metadata.description}
              </a>
            ) : null
          )}
        </div> */}
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
