import React from "react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";

function UIFacetLink({ facetComponentId, item }) {
  const history = useHistory();

  if (!facetComponentId || !item) {
    return "";
  }

  let facetValue = item.role
    ? `${item.term.label} (${item.role.label})`
    : item.term.label;

  const handleClick = () => {
    history.push("/search", {
      externalFacet: {
        facetComponentId,
        value: facetValue,
      },
    });
  };

  return (
    <a data-testid="facet-link" className="break-word" onClick={handleClick}>
      {facetValue}
    </a>
  );
}

UIFacetLink.propTypes = {
  facetComponentId: PropTypes.string.isRequired,
  item: PropTypes.object.isRequired,
};

export default UIFacetLink;
