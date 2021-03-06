import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import { UNCONTROLLED_METADATA } from "@js/services/metadata";

const WorkTabsAboutUncontrolledMetadata = ({
  descriptiveMetadata,
  isEditing,
}) => {
  return (
    <div className="columns is-multiline" data-testid="uncontrolled-metadata">
      {UNCONTROLLED_METADATA.map((item) => (
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
    </div>
  );
};

WorkTabsAboutUncontrolledMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
};

export default WorkTabsAboutUncontrolledMetadata;
