import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import { IDENTIFIER_METADATA } from "@js/services/metadata";
import UIFormRelatedURL from "@js/components/UI/Form/RelatedURL";
import { useCodeLists } from "@js/context/code-list-context";
import {
  OriginBadge,
  fieldProvenance,
  provenanceItemId,
} from "@js/components/AIProvenance/Badges";

const WorkTabsAboutIdentifiersMetadata = ({
  work,
  isEditing,
  provenance = {},
}) => {
  const codeLists = useCodeLists();
  const { ark, descriptiveMetadata } = work;

  // Per-URL AI origin, keyed by url (the backend's item identifier), so each
  // related URL is badged individually rather than with one field-level badge.
  const relatedUrlOriginById = (
    fieldProvenance(provenance, "relatedUrl")?.itemProvenance || []
  ).reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  return (
    <div className="columns is-multiline" data-testid="identifiers-metadata">
      <div className="column is-half" key="ark" data-testid="ark">
        <div className="field content">
          <p data-testid="items-label">
            <strong>ARK</strong>
          </p>
          <ul data-testid="field-array-item-list">
            <li key="ark-value">{ark}</li>
          </ul>
        </div>
      </div>

      {IDENTIFIER_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray required name={item.name} label={item.label} />
          ) : (
            <UIFormFieldArrayDisplay
              values={descriptiveMetadata[item.name]}
              label={item.label}
              provenance={fieldProvenance(provenance, item.name)}
            />
          )}
        </div>
      ))}
      {/* RelatedURL entry is the only field which is an array of RelatedUrlEntries
       which is a combination of array of label object and string URL */}
      <div className="column" data-testid="relatedUrl">
        <UIFormField label="Related URL">
          {isEditing ? (
            <UIFormRelatedURL
              codeLists={
                codeLists.relatedUrlData
                  ? codeLists.relatedUrlData.codeList
                  : []
              }
              label="Related URL"
              name="relatedUrl"
            />
          ) : (
            <div className="field content">
              <ul data-testid="field-array-item-list">
                {descriptiveMetadata.relatedUrl.map((relatedUrlEntry, i) => {
                  const origin =
                    relatedUrlOriginById[provenanceItemId(relatedUrlEntry)];
                  return (
                    <li className="mb-4" key={i}>
                      {relatedUrlEntry.label.label} - {relatedUrlEntry.url}
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
          )}
        </UIFormField>
      </div>
    </div>
  );
};

WorkTabsAboutIdentifiersMetadata.propTypes = {
  work: PropTypes.object,
  isEditing: PropTypes.bool,
  provenance: PropTypes.object,
};

export default WorkTabsAboutIdentifiersMetadata;
