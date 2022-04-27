import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

function CollectionImage({ collection, ...restProps }) {
  if (!collection) return null;
  const { id, representativeWork } = collection;

  return (
    <Link to={`/collection/${id}`} {...restProps}>
      <img
        src={
          representativeWork
            ? `${representativeWork.representativeImage}/square/500,500/0/default.jpg`
            : "/images/placeholder.png"
        }
      />
    </Link>
  );
}

CollectionImage.propTypes = {
  collection: PropTypes.object,
};

export default CollectionImage;
