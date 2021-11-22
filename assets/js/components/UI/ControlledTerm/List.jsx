import React from "react";
import PropTypes from "prop-types";
import { IconExternalLink } from "@js/components/Icon";
import { FACET_SENSORS } from "../../../services/reactive-search";
import UIFacetLink from "../FacetLink";
import UITooltip from "@js/components/UI/Tooltip/Tooltip";

const UIControlledTermList = ({ items = [], title }) => {
  const { componentId } =
    FACET_SENSORS.find((facet) => facet.title === title) || {};

  return (
    <div className="content mb-4">
      <ul data-testid="controlled-term-list" className="ml-0">
        {items.map((item) => (
          <li
            key={`${item.term.id}-${item.role ? item.role.id : ""}`}
            data-testid="controlled-term-list-row"
            className="is-flex is-flex-direction-column is-align-items-flex-start"
          >
            <UITooltip>
              <div className="tooltip-header">
                {componentId ? (
                  <UIFacetLink facetComponentId={componentId} item={item} />
                ) : (
                  item.term.label
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
    })
  ),
};

export default UIControlledTermList;
