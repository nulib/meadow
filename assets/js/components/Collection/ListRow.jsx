import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

const CollectionListRow = ({ collection, onOpenModal }) => {
  const {
    id,
    title = "",
    description = "",
    keywords = [],
    representativeWork,
  } = collection;
  return (
    <li data-testid="collection-list-row" className="mb-4">
      <article className="media">
        <figure className="media-left">
          <p className="image is-128x128">
            <Link to={`/collection/${id}`} className="hvr-shrink">
              <img
                src={
                  representativeWork
                    ? `${representativeWork.representativeImage}/square/500,500/0/default.jpg`
                    : "/images/placeholder.png"
                }
              />
            </Link>
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
            <p>
              <strong className="is-size-5">
                <Link to={`/collection/${id}`}>{title}</Link>
              </strong>{" "}
              <br />
              {description}
            </p>
            <table className="table is-fullwidth">
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
