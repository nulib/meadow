import React from "react";
import PropTypes from "prop-types";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";

const UIFormFieldArrayDisplay = ({
  isFacetLink,
  label,
  metadataItem,
  values = [],
}) => {
  const { handleFacetLinkClick } = useFacetLinkClick();

  return (
    <div className="field content block">
      <p data-testid="items-label">
        <strong>{label}</strong>
      </p>
      <ul data-testid="field-array-item-list">
        {values.map((value, i) => (
          <li key={i}>
            {isFacetLink ? (
              <a
                onClick={() =>
                  handleFacetLinkClick(metadataItem?.facetComponentId, value)
                }
              >
                {value}
              </a>
            ) : (
              value
            )}
          </li>
        ))}
      </ul>
    </div>
  );
};

UIFormFieldArrayDisplay.propTypes = {
  isFacetLink: PropTypes.bool,
  label: PropTypes.string,
  metadataItem: PropTypes.object,
  values: PropTypes.array,
};

export default UIFormFieldArrayDisplay;
