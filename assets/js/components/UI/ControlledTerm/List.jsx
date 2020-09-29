import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { FACET_SENSORS } from "../../../services/reactive-search";
import UIFacetLink from "../FacetLink";

const UIControlledTermList = ({ items = [], title }) => {
  const { componentId } =
    FACET_SENSORS.find((facet) => facet.title === title) || {};

  return (
    <div className="content mb-4">
      <ul data-testid="controlled-term-list">
        {items.map((item) => (
          <li
            key={`${item.term.id}-${item.role ? item.role.id : ""}`}
            data-testid="controlled-term-list-row"
          >
            {componentId ? (
              <UIFacetLink facetComponentId={componentId} item={item} />
            ) : (
              item.term.label
            )}
            {item.term.id && (
              <a
                href={item.term.id}
                target="_blank"
                className="ml-1"
                data-testid="external-link"
              >
                - {item.term.id}
                <span className="icon" title={item.term.id}>
                  <FontAwesomeIcon icon="external-link-alt" />
                </span>
              </a>
            )}
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
