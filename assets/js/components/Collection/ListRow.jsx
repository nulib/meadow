import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import CollectionTags from "@js/components/Collection/Tags";
import CollectionImage from "@js/components/Collection/Image";

const CollectionListRow = ({ collection, onOpenModal }) => {
  const {
    id,
    title = "",
    description = "",
    keywords = [],
    representativeWork,
  } = collection;
  return (
    <li data-testid="collection-list-row" className="mb-6">
      <article className="media">
        <figure className="media-left">
          <p className="image is-128x128">
            <CollectionImage collection={collection} />
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
            <h4>
              <Link to={`/collection/${id}`}>{title}</Link>
            </h4>
            <CollectionTags collection={collection} />
            {/* <p>{description}</p> */}
            <table className="table is-fullwidth is-narrow">
              <thead>
                <tr>
                  <th>Keywords</th>
                  <th>Works [not yet supported]</th>
                  <th>Assets [not yet supported]</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>{keywords.join(", ")}</td>
                  <td>3810 works, 2010 public, 700 netid, 100 private</td>
                  <td>100,000 preserved files</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div className="media-right">
          <div className="buttons-end">
            <AuthDisplayAuthorized action="edit">
              <p className="control">
                <Link className="button" to={`/collection/form/${id}`}>
                  <FontAwesomeIcon icon="edit" />
                </Link>
              </p>
            </AuthDisplayAuthorized>
            <AuthDisplayAuthorized action="delete">
              <p className="control">
                <button
                  className="button"
                  onClick={() => onOpenModal({ id, title })}
                >
                  <FontAwesomeIcon icon="trash" />
                </button>
              </p>
            </AuthDisplayAuthorized>
          </div>
        </div>
      </article>
    </li>
  );
};

CollectionListRow.propTypes = {
  collection: PropTypes.object,
};

export default CollectionListRow;
