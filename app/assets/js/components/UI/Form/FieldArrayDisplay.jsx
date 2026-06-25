import React from "react";
import PropTypes from "prop-types";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import {
  FieldProvenanceBadge,
  OriginBadge,
  activeFieldOrigin,
  provenanceTooltip,
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

  // Map of value -> AI origin so each value can be badged individually (e.g. an
  // AI-generated alternate title next to one a human added). For plain-string
  // fields the provenance item id is the value itself.
  const originByValue = itemProvenance.reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  // When a field carries per-item provenance, every value gets its own badge:
  // values the AI proposed match by id; values a human has since edited no
  // longer match that id, so they fall back to the field's overall origin
  // (e.g. "AI + human edited") rather than losing their badge entirely.
  const fieldOrigin = activeFieldOrigin(provenance);
  const tooltip = provenanceTooltip(provenance);

  return (
    <>
      <div className="field content block">
        <p data-testid="items-label">
          <strong>{label}</strong>
        </p>
        <ul data-testid="field-array-item-list">
          {values.map((value, i) => {
            const matched = originByValue[value];
            const origin =
              matched ?? (itemProvenance.length ? fieldOrigin : undefined);
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
                    <OriginBadge
                      origin={origin}
                      title={matched ? undefined : tooltip || undefined}
                    />
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
