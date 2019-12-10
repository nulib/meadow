import React from "react";
import PropTypes from "prop-types";
import Collection from "./Collection";

const CollectionList = ({ collections = [] }) => {
  if (collections.length === 0) {
    return null;
  }
  return (
    <div data-testid="collection-list">
      {collections.map(collection => (
        <div key={collection.id} className="my-8">
          <Collection collection={collection} />
        </div>
      ))}
    </div>
  );
};

CollectionList.propTypes = {
  collections: PropTypes.array
};

export default CollectionList;
