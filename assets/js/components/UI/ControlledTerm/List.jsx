import React from "react";
import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { FACET_SENSORS } from "../../../services/reactive-search";

const UIControlledTermList = ({ items = [], title }) => {
  const { componentId } =
    FACET_SENSORS.find((facet) => facet.title === title) || {};

  const linkElement = (item) => {
    const itemLabel = item.role ? ` (${item.role.label})` : "";
    let adjustedSearchValue = item.term.label
      .concat(itemLabel)
      .split(" ")
      .join("+");
    let encoded = encodeURI(`${componentId}=["${adjustedSearchValue}"]`);
    return <Link to={`/search?${encoded}`}>{item.term.label}</Link>;
  };

  return (
    <div className="content mb-4">
      <ul data-testid="controlled-term-list">
        {items.map((item) => (
          <li key={`${item.term.id}-${item.role ? item.role.id : ""}`}>
            {componentId ? linkElement(item) : item.term.label}
            {item.role && ` (${item.role.label})`}
            {item.term.id && (
              <a
                href={item.term.id}
                target="_blank"
                className="has-text-black ml-1"
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
