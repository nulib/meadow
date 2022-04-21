import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import { IDENTIFIER_METADATA } from "@js/services/metadata";
import UIFormRelatedURL from "@js/components/UI/Form/RelatedURL";
import { useCodeLists } from "@js/context/code-list-context";

const WorkTabsAboutIdentifiersMetadata = ({
  descriptiveMetadata,
  isEditing,
}) => {
  const codeLists = useCodeLists();

  return (
    <div className="columns is-multiline" data-testid="identifiers-metadata">
      <div className="column is-half" key="ark" data-testid="ark">
        <div className="field content">
          <p data-testid="items-label">
            <strong>ARK</strong>
          </p>
          <ul data-testid="field-array-item-list">
            <li key="ark-value">{descriptiveMetadata.ark}</li>
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
                {descriptiveMetadata.relatedUrl.map((relatedUrlEntry, i) => (
                  <li className="mb-4" key={i}>
                    {relatedUrlEntry.label.label} - {relatedUrlEntry.url}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </UIFormField>
      </div>
    </div>
  );
};

WorkTabsAboutIdentifiersMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
};

export default WorkTabsAboutIdentifiersMetadata;
