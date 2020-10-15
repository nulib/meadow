import React from "react";
import PropTypes from "prop-types";
import UIFormBatchFieldArray from "../../UI/Form/BatchFieldArray";
import { UNCONTROLLED_METADATA } from "../../../services/metadata";

const BatchEditAboutUncontrolledMetadata = ({ ...restProps }) => {
  return (
    <div
      className="columns is-multiline"
      data-testid="uncontrolled-metadata"
      {...restProps}
    >
      {UNCONTROLLED_METADATA.map((item) => (
        <div key={item.name} className="column is-half" data-testid={item.name}>
          <UIFormBatchFieldArray required name={item.name} label={item.label} />
        </div>
      ))}
    </div>
  );
};

BatchEditAboutUncontrolledMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutUncontrolledMetadata;
