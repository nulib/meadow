import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import { PHYSICAL_METADATA } from "../../../services/metadata";

const BatchEditAboutPhysicalMetadata = ({ ...restProps }) => {
  return (
    <div
      className="columns is-multiline"
      data-testid="physical-metadata"
      {...restProps}
    >
      {PHYSICAL_METADATA.map((item) => (
        <div key={item.name} className="column is-half" data-testid={item.name}>
          <UIFormFieldArray required name={item.name} label={item.label} />
        </div>
      ))}
    </div>
  );
};

BatchEditAboutPhysicalMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutPhysicalMetadata;
