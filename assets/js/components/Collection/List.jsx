import React from "react";
import PropTypes from "prop-types";
import CollectionListRow from "../../components/Collection/ListRow";

function CollectionList({ collections, filteredCollections, onOpenModal }) {
  return (
    <div>
      <ul>
        {filteredCollections.length > 0 &&
          filteredCollections.map((collection) => (
            <CollectionListRow
              key={collection.id}
              collection={collection}
              onOpenModal={onOpenModal}
            />
          ))}
      </ul>
      {collections.length === 0 && (
        <div className="content">
          <p className="notification">No collections returned</p>
        </div>
      )}
    </div>
  );
}

CollectionList.propTypes = {
  collections: PropTypes.array,
  filteredCollections: PropTypes.array,
  onOpenModal: PropTypes.func,
};

export default CollectionList;
