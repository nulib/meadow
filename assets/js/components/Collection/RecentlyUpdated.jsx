import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import { GET_COLLECTIONS } from "@js/components/Collection/collection.gql.js";
import UISkeleton from "@js/components/UI/Skeleton";
import CollectionImage from "@js/components/Collection/Image";
import { Link } from "react-router-dom";

function CollectionRecentlyUpdated({ recentlyUpdatedCollections = [] }) {
  const { data, loading, error } = useQuery(GET_COLLECTIONS);

  if (error) return <p>Error loading collections</p>;
  if (loading) return <UISkeleton />;

  const updatedIds = recentlyUpdatedCollections.map((c) => c.id);
  const fullCollections = data.collections.filter((apiCollection) => {
    return updatedIds.includes(apiCollection.id);
  });

  return (
    <div>
      {fullCollections.map((c) => (
        <article key={c.id} className="media">
          <figure className="media-left">
            <div className="image is-128x128">
              <CollectionImage collection={c} />
            </div>
          </figure>
          <div className="media-content">
            <div className="content">
              <h4>{c.title}</h4>
              <Link className="button" to={`/collection/${c.id}`}>
                View Collection
              </Link>
            </div>
          </div>
        </article>
      ))}
    </div>
  );
}

CollectionRecentlyUpdated.propTypes = {
  recentlyUpdatedCollections: PropTypes.array,
};

export default CollectionRecentlyUpdated;
