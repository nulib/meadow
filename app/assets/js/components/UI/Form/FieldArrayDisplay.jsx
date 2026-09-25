import React from "react";
import PropTypes from "prop-types";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import {
  FieldProvenanceBadge,
  OriginBadge,
} from "@js/components/AIProvenance/Badges";
import { ItemAttestation } from "@js/components/AIProvenance/ItemAttestationControl";

const UIFormFieldArrayDisplay = ({
  isFacetLink,
  label,
  metadataItem,
  provenance,
  values = [],
  workId,
}) => {
  const { handleFacetLinkClick } = useFacetLinkClick();

  const itemProvenance = provenance?.itemProvenance || [];

  // Map of item id -> AI origin so each AI-attributed value can be badged
  // individually (e.g. an AI-generated alternate title next to one a human
  // added). Repeating free-text items now carry a stable embed id, so per-item
  // attribution keys on that id rather than the value or list position; an item
  // the AI generated keeps its badge even after a human edits it in place.
  const originById = itemProvenance.reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  // Repeating free-text values are `{ id, value }` objects; fall back to the raw
  // string for any legacy/plain value.
  const itemValue = (entry) =>
    entry && typeof entry === "object" ? entry.value : entry;
  const itemId = (entry) =>
    entry && typeof entry === "object" ? entry.id : entry;

  return (
    <>
      <div className="field content block">
        <p data-testid="items-label">
          <strong>{label}</strong>
        </p>
        <ul data-testid="field-array-item-list">
          {values.map((entry, i) => {
            const value = itemValue(entry);
            const origin = originById[itemId(entry)];
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
                {origin && (
                  <ItemAttestation
                    origin={origin}
                    workId={workId}
                    fieldPath={provenance?.fieldPath}
                    itemId={itemId(entry)}
                  />
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
  workId: PropTypes.string,
};

export default UIFormFieldArrayDisplay;
