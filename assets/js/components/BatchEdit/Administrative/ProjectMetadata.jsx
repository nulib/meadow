import React from "react";
import PropTypes from "prop-types";
import UIFormBatchFieldArray from "../../UI/Form/BatchFieldArray";
import { PROJECT_METADATA } from "../../../services/metadata";

const BatchEditAdministrativeProjectMetadata = ({ ...restProps }) => {
  return (
    <div
      className="columns is-multiline"
      data-testid="project-metadata"
      {...restProps}
    >
      {PROJECT_METADATA.map((item) => (
        <div
          key={item.name}
          className="column is-one-third"
          data-testid={item.name}
        >
          <UIFormBatchFieldArray required name={item.name} label={item.label} />
        </div>
      ))}
    </div>
  );
};

BatchEditAdministrativeProjectMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAdministrativeProjectMetadata;
