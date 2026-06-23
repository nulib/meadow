import React from "react";
import PropTypes from "prop-types";
import { IconExternalLink } from "@js/components/Icon";
import { FACET_SENSORS } from "../../../services/reactive-search";
import UIFacetLink from "../FacetLink";
import UITooltip from "@js/components/UI/Tooltip/Tooltip";
import { OriginBadge } from "@js/components/AIProvenance/Badges";

const UIControlledTermList = ({ items = [], title, itemProvenance = [] }) => {
  const { componentId } =
    FACET_SENSORS.find((facet) => facet.title === title) || {};

  // Map of term id -> AI origin, so each term can be badged individually
  // (e.g. AI-generated subjects vs. one a human added later).
  const originById = itemProvenance.reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  return (
    <div className="content mb-4">
      <ul data-testid="controlled-term-list">
        {items.map((item) => (
          <li
            key={`${item.term.id}-${item.role ? item.role.id : ""}`}
            data-testid="controlled-term-list-row"
          >
            <div className="is-flex is-flex-direction-column is-align-items-flex-start">
              <UITooltip>
                <div className="tooltip-header">
                  {componentId ? (
                    <UIFacetLink facetComponentId={componentId} item={item} />
                  ) : (
                    item.term?.label || item.term?.id
                  )}
                  {originById[item.term?.id] && (
                    <span className="ml-2">
                      <OriginBadge origin={originById[item.term.id]} />
                    </span>
                  )}
                </div>
                <div className="tooltip-content">
                  {item.term.id && (
                    <a
                      href={item.term.id}
                      target="_blank"
                      className="button is-text is-small"
                      style={{
                        textTransform: "none",
                        backgroundColor: "#4e2a84",
                        color: "white",
                      }}
                      data-testid="external-link"
                    >
                      <span className="icon" title={item.term.id}>
                        <IconExternalLink />
                      </span>
                      <span>{item.term.id}</span>
                    </a>
                  )}
                </div>
              </UITooltip>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
};

UIControlledTermList.propTypes = {
  items: PropTypes.arrayOf(
    PropTypes.shape({
      role: PropTypes.shape({
        id: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
        scheme: PropTypes.string,
      }),
      term: PropTypes.shape({
        id: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
      }),
    }),
  ),
  itemProvenance: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      origin: PropTypes.string,
    }),
  ),
};

export default UIControlledTermList;
