import React from "react";
import PropTypes from "prop-types";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import {
  FieldProvenanceBadge,
  OriginBadge,
} from "@js/components/AIProvenance/Badges";

const UIFormFieldArrayDisplay = ({
  isFacetLink,
  label,
  metadataItem,
  provenance,
  values = [],
}) => {
  const { handleFacetLinkClick } = useFacetLinkClick();

  const itemProvenance = provenance?.itemProvenance || [];

  // Map of value -> AI origin so each AI-attributed value can be badged
  // individually (e.g. an AI-generated alternate title next to one a human
  // added). The backend reconciles each item against the AI's proposal, so an
  // item the AI generated keeps its badge even after a human edits it in place
  // (the entry is keyed by the item's current value). For plain-string fields
  // the provenance item id is the value itself; values with no matching entry
  // were added by a human and carry no AI attribution, so they stay unbadged.
  const originByValue = itemProvenance.reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  return (
    <>
      <div className="field content block">
        <p data-testid="items-label">
          <strong>{label}</strong>
        </p>
        <ul data-testid="field-array-item-list">
          {values.map((value, i) => {
            const origin = originByValue[value];
            return (
              <li key={i}>
                {isFacetLink ? (
                  <a
                    onClick={() =>
                      handleFacetLinkClick(
                        metadataItem?.facetComponentId,
                        value,
                      )
                    }
                  >
                    {value}
                  </a>
                ) : (
                  value
                )}
                {origin && (
                  <span className="ml-2">
                    <OriginBadge origin={origin} />
                  </span>
                )}
              </li>
            );
          })}
        </ul>
      </div>
      {/* Fields with no per-item provenance keep a single field-level badge. */}
      {itemProvenance.length === 0 && (
        <FieldProvenanceBadge entry={provenance} />
      )}
    </>
  );
};

UIFormFieldArrayDisplay.propTypes = {
  isFacetLink: PropTypes.bool,
  label: PropTypes.string,
  metadataItem: PropTypes.object,
  provenance: PropTypes.object,
  values: PropTypes.array,
};

export default UIFormFieldArrayDisplay;
