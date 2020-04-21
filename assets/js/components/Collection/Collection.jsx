import React from "react";
import PropTypes, { shape } from "prop-types";

const Collection = ({
  adminEmail,
  description,
  findingAidUrl,
  keywords = []
}) => {
  return (
    <div data-testid="collection">
      <div className="columns">
        <div className="column is-one-quarter-desktop is-half-tablet">
          <figure className="image is-square">
            <img src="https://bulma.io/images/placeholders/480x480.png" />
          </figure>
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
            <dd>{findingAidUrl}</dd>
            <dt>
              <strong>Keywords</strong>
            </dt>
            <dd>{keywords.join(", ")}</dd>
          </dl>
        </div>
      </div>
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
    works: PropTypes.array
  })
};

export default Collection;
