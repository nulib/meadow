import React, { useState } from "react";
import PropTypes, { shape } from "prop-types";
import CollectionSearch from "./Search";

const Collection = ({
  id,
  adminEmail,
  description,
  featured,
  findingAidUrl,
  keywords = [],
  name,
  published,
  works = []
}) => {


  return (
    <div className="container" data-testid="collection">
      <article className="media">
        <figure className="media-left">
          <p
            className="image is-square"
            style={{ width: "300px", height: "300px" }}
          >
            <img src="https://bulma.io/images/placeholders/480x480.png" />
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
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
        <div className="media-right"></div>
      </article>

      <CollectionSearch />
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
