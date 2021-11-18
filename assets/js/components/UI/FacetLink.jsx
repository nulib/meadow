import React from "react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { Button } from "@nulib/design-system";

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
    <Button
      isText
      data-testid="facet-link"
      className="break-word"
      onClick={handleClick}
      css={{ padding: "0", textTransform: "none !important" }}
    >
      <span>{facetValue}</span>
    </Button>
  );
}

UIFacetLink.propTypes = {
  facetComponentId: PropTypes.string.isRequired,
  item: PropTypes.object.isRequired,
};

export default UIFacetLink;
