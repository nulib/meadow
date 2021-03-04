import React, { useState } from "react";
import PropTypes, { shape } from "prop-types";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { Button } from "@nulib/admin-react-components";
import { Link, useHistory } from "react-router-dom";
import IconEdit from "@js/components/Icon/Edit";
import IconImages from "@js/components/Icon/Images";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const imgCol = css`
  border-right: 1px solid #efefef;
  margin-right: 1rem;
  padding-right: 1rem;
`;

const Collection = ({ collection }) => {
  const history = useHistory();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const {
    adminEmail,
    description,
    representativeWork,
    findingAidUrl,
    keywords = [],
  } = collection;

  const handleViewAllWorksClick = () => {
    history.push("/search", {
      externalFacet: {
        facetComponentId: "Collection",
        value: collection.title,
      },
    });
  };

  return (
    <div data-testid="collection">
      <div className="columns">
        <div
          className="column is-one-quarter-desktop is-half-tablet"
          css={imgCol}
        >
          <figure className="image is-square">
            {representativeWork ? (
              <Link to={`/work/${representativeWork.id}`} title="View work">
                <img
                  className="hvr-shrink"
                  src={`${representativeWork.representativeImage}/square/500,500/0/default.jpg`}
                />
              </Link>
            ) : (
              <img src="/images/placeholder.png" />
            )}
          </figure>
          <AuthDisplayAuthorized>
            <p className="has-text-centered pt-2">
              <Button
                data-testid="button-open-image-modal"
                isText
                onClick={handleViewAllWorksClick}
                className="is-fullwidth"
              >
                <span className="icon">
                  <IconEdit />
                </span>
                <span>Update Image</span>
              </Button>
            </p>
          </AuthDisplayAuthorized>
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
          <AuthDisplayAuthorized>
            <div className="pt-3">
              <Button
                onClick={handleViewAllWorksClick}
                data-testid="view-works-button"
              >
                <span className="icon">
                  <IconImages />
                </span>
                <span>View collection works</span>
              </Button>
            </div>
          </AuthDisplayAuthorized>
        </div>
      </div>
    </div>
  );
};

Collection.propTypes = {
  collection: shape({
    id: PropTypes.string.isRequired,
    title: PropTypes.string,
    description: PropTypes.string,
    keywords: PropTypes.array,
    adminEmail: PropTypes.string,
    featured: PropTypes.bool,
    findingAidUrl: PropTypes.string,
    works: PropTypes.array,
  }),
};

export default Collection;
