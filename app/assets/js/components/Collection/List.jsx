import React from "react";
import PropTypes from "prop-types";
import CollectionListRow from "@js/components/Collection/ListRow";
import { Notification } from "@nulib/design-system";

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
          <Notification>No collections returned</Notification>
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
