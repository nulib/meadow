import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import { IDENTIFIER_METADATA } from "../../../services/metadata";

const BatchEditAboutIdentifiersMetadata = ({
  control,
  errors,
  register,
  ...restProps
}) => {
  return (
    <div
      className="columns is-multiline"
      data-testid="identifiers-metadata"
      {...restProps}
    >
      {IDENTIFIER_METADATA.map((item) => (
        <div key={item.name} className="column is-half" data-testid={item.name}>
          <UIFormFieldArray
            register={register}
            control={control}
            required
            name={item.name}
            label={item.label}
            errors={errors}
          />
        </div>
      ))}
    </div>
  );
};

BatchEditAboutIdentifiersMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  errors: PropTypes.object,
  register: PropTypes.func.isRequired,
  restProps: PropTypes.object,
};

export default BatchEditAboutIdentifiersMetadata;
