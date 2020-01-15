import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import EditIcon from "../../../css/fonts/zondicons/edit-pencil.svg";
import UICard from "../UI/Card";

const CollectionListRow = ({ collection }) => {
  const { id, name = "", description = "", keywords = [] } = collection;
  return (
    <li data-testid="collection-list-row">
      <UICard>
        <header className="flex justify-between">
          <h2 className="mt-0">
            <Link to={`/collection/${id}`}>{name}</Link>
          </h2>
          <Link to={`/collection/form/${id}`}>
            <EditIcon className="icon" /> <span className="sr-only">Edit</span>
          </Link>
        </header>
        <div className="flex flex-col sm:flex-row">
          <img
            src="/images/placeholder-content.png"
            alt="Placeholder for collection"
            className="sm:max-w-xs sm:pr-4"
          />
          <dl className="">
            <dt>Description</dt>
            <dd>{description}</dd>
            <dt>Keywords</dt>
            <dd>{keywords.join(", ")}</dd>
            <dt>Works [not yet supported]</dt>
            <dd>3810 works, 2010 public, 700 netid, 100 private</dd>
            <dt>Assets [not yet supported]</dt>
            <dd>100,000 preserved files</dd>
          </dl>
        </div>
      </UICard>
    </li>
  );
};

CollectionListRow.propTypes = {
  collection: PropTypes.object
};

export default CollectionListRow;
