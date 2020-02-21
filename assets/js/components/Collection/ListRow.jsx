import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const CollectionListRow = ({ collection, onOpenModal }) => {
  const { id, name = "", description = "", keywords = [] } = collection;
  const styles = { listItem: { marginBottom: "1rem" } };
  return (
    <li data-testid="collection-list-row" style={styles.listItem}>
      <article className="media">
        <figure className="media-left">
          <p className="image is-128x128">
            <img src="https://bulma.io/images/placeholders/128x128.png" />
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
            <p>
              <strong className="is-size-5">
                <Link to={`/collection/${id}`}>{name}</Link>
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
            <p className="control">
              <Link className="button" to={`/collection/form/${id}`}>
                <FontAwesomeIcon icon="edit" />
              </Link>
            </p>
            <p className="control">
              <button
                className="button"
                onClick={() => onOpenModal({ id, name })}
              >
                <FontAwesomeIcon icon="trash" />
              </button>
            </p>
          </div>
        </div>
      </article>
    </li>
  );
};

CollectionListRow.propTypes = {
  collection: PropTypes.object
};

export default CollectionListRow;
