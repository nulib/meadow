import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import { METADATA_FIELDS, PHYSICAL_METADATA } from "@js/services/metadata";
import { fieldProvenance } from "@js/components/AIProvenance/Badges";

const { BOX_NAME, BOX_NUMBER, FOLDER_NAME, FOLDER_NUMBER, SERIES } =
  METADATA_FIELDS;
const itemsToLink = [BOX_NAME, BOX_NUMBER, FOLDER_NAME, FOLDER_NUMBER, SERIES];

const WorkTabsAboutPhysicalMetadata = ({
  descriptiveMetadata,
  isEditing,
  provenance = {},
}) => {
  return (
    <div className="columns is-multiline" data-testid="physical-metadata">
      {PHYSICAL_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray required name={item.name} label={item.label} />
          ) : (
            <UIFormFieldArrayDisplay
              values={descriptiveMetadata[item.name]}
              isFacetLink={Boolean(
                itemsToLink.find((o) => o.name === item.name),
              )}
              label={item.label}
              metadataItem={item}
              provenance={fieldProvenance(provenance, item.name)}
            />
          )}
        </div>
      ))}
    </div>
  );
};

WorkTabsAboutPhysicalMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
  provenance: PropTypes.object,
};

export default WorkTabsAboutPhysicalMetadata;
