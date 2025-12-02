import React, { useState } from "react";
import PropTypes, { shape } from "prop-types";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { Button } from "@nulib/design-system";
import { Link, useHistory } from "react-router-dom";
import { IconEdit, IconImages } from "@js/components/Icon";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const Collection = ({ collection }) => {
  const history = useHistory();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const {
    adminEmail,
    description,
    representativeWork,
    findingAidUrl,
    keywords = [],
    totalWorks,
    stats,
  } = collection;

  const handleViewAllWorksClick = () => {
    history.push("/search", {
      externalFacet: {
        facetComponentId: "Collection",
        value: collection.title,
      },
    });
  };

  const handleFacetClick = (facetComponentId, facetValue) => {
    const collectionFacet = `Collection=${encodeURIComponent(JSON.stringify([collection.title]))}`;
    const additionalFacet = `${facetComponentId}=${encodeURIComponent(JSON.stringify([facetValue]))}`;
    history.push(`/search?${collectionFacet}&${additionalFacet}`);
  };

  return (
    <div data-testid="collection">
      <div className="columns">
        <div className="column is-one-quarter-desktop is-half-tablet">
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
          {totalWorks > 0 && (
            <AuthDisplayAuthorized>
              <p className="has-text-centered pt-2">
                <Button
                  data-testid="button-open-image-modal"
                  isText
                  onClick={handleViewAllWorksClick}
                  className="is-fullwidth"
                >
                  <IconEdit />
                  <span>Update Image</span>
                </Button>
              </p>
            </AuthDisplayAuthorized>
          )}
        </div>
        <div className="column content">
          <dl className="spaced">
            <dt>
              <strong>Description</strong>
            </dt>
            <dd style={{ whiteSpace: "pre-line" }}>{description}</dd>
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
            <dt>
              <strong>Total Works</strong>
            </dt>
            <dd>{totalWorks}</dd>
            {stats && (
              <>
                <dt>
                  <strong>Work Statistics</strong>
                </dt>
                <dd>
                  <ul>
                    <li>
                      <a
                        onClick={() => handleViewAllWorksClick()}
                        style={{ cursor: "pointer" }}
                      >
                        Total Works ({stats.total})
                      </a>
                    </li>
                    <li>
                      <a
                        onClick={() => handleFacetClick("Published", false)}
                        style={{ cursor: "pointer" }}
                      >
                        Unpublished ({stats.unpublished})
                      </a>
                    </li>
                    <li>
                      <a
                        onClick={() => handleFacetClick("Published", true)}
                        style={{ cursor: "pointer" }}
                      >
                        Published ({stats.published})
                      </a>
                    </li>
                    <li>
                      <a
                        onClick={() => handleFacetClick("WorkType", "Video")}
                        style={{ cursor: "pointer" }}
                      >
                        Video ({stats.video})
                      </a>
                    </li>
                    <li>
                      <a
                        onClick={() => handleFacetClick("WorkType", "Audio")}
                        style={{ cursor: "pointer" }}
                      >
                        Audio ({stats.audio})
                      </a>
                    </li>
                    <li>
                      <a
                        onClick={() => handleFacetClick("WorkType", "Image")}
                        style={{ cursor: "pointer" }}
                      >
                        Image ({stats.image})
                      </a>
                    </li>
                  </ul>
                </dd>
              </>
            )}
          </dl>
          {totalWorks > 0 && (
            <div className="pt-3">
              <Button
                onClick={handleViewAllWorksClick}
                data-testid="view-works-button"
              >
                <IconImages />
                <span>View collection works</span>
              </Button>
            </div>
          )}
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
