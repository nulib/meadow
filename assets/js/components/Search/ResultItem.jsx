import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { IIIFContext } from "../IIIF/IIIFProvider";
import { setVisibilityClass } from "../../services/helpers";

const SearchResultItem = ({ res }) => {
  const iiifServerUrl = useContext(IIIFContext);

  const {
    _id,
    accession_number,
    file_sets = [],
    model,
    representative_file_set_id,
    published,
    title,
    visibility
  } = res;
  const fileSetsToDisplay = 5;

  return (
    <div className="card is-shadowless">
      <div className="card-image">
        <figure className="image is-square">
          {file_sets.length > 0 && (
            <Link to={`/work/${_id}`}>
              <img
                src={`${iiifServerUrl}${representative_file_set_id}/square/500,500/0/default.jpg`}
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
          Filesets <span className="tag is-light">{file_sets.length}</span>
        </h4>
        <div className="list is-hoverable has-background-light">
          {file_sets.map((fileSet, i) =>
            i < fileSetsToDisplay - 1 ? (
              <p key={fileSet.id} className="list-item">
                {fileSet.label}
              </p>
            ) : null
          )}
        </div>
        <p>
          <span className={`tag ${setVisibilityClass(visibility)}`}>
            {visibility.toUpperCase()}
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
