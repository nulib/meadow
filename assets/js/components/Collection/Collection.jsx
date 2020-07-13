import React, { useState } from "react";
import PropTypes, { shape } from "prop-types";
import CollectionImageModal from "./CollectionImageModal";
import { Link } from "react-router-dom";

const Collection = ({ collection }) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const {
    adminEmail,
    description,
    representativeWork,
    findingAidUrl,
    keywords = [],
    works,
  } = collection;

  const onCloseModal = () => {
    setIsModalOpen(false);
  };

  return (
    <div data-testid="collection">
      <div className="columns">
        <div className="column is-one-quarter-desktop is-half-tablet">
          <figure className="image is-square">
            <img
              src={
                representativeWork
                  ? `${representativeWork.representativeImage}/square/500,500/0/default.jpg`
                  : "/images/480x480.png"
              }
            />
          </figure>
          {works.length > 0 && (
            <p className="has-text-centered pt-4">
              <button
                data-testid="button-open-image-modal"
                type="button"
                className="button is-light is-small"
                onClick={() => setIsModalOpen(true)}
              >
                Update Image
              </button>
            </p>
          )}
        </div>
        <div className="column content">
          <dl>
            <dt>
              <strong>Description</strong>
            </dt>
            <dd>{description}</dd>
            <dt>
              <strong>Admin Email</strong>
            </dt>
            <dd>{adminEmail}</dd>
            <dt>
              <strong>Finding Aid URL</strong>
            </dt>
            <dd>
              <a href={findingAidUrl} target="_blank">
                {findingAidUrl}
              </a>
            </dd>
            <dt>
              <strong>Keywords</strong>
            </dt>
            <dd>{keywords.join(", ")}</dd>
          </dl>
        </div>
      </div>
      <CollectionImageModal
        collection={collection}
        isModalOpen={isModalOpen}
        handleClose={onCloseModal}
      />
    </div>
  );
};

Collection.propTypes = {
  collection: shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string,
    description: PropTypes.string,
    keywords: PropTypes.array,
    adminEmail: PropTypes.string,
    featured: PropTypes.bool,
    findingAidUrl: PropTypes.string,
    works: PropTypes.array,
  }),
};

export default Collection;
