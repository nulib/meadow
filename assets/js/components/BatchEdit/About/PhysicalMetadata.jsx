import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import { PHYSICAL_METADATA } from "../../../services/metadata";

const BatchEditAboutPhysicalMetadata = ({
  control,
  errors,
  register,
  ...restProps
}) => {
  return (
    <div
      className="columns is-multiline"
      data-testid="physical-metadata"
      {...restProps}
    >
      {PHYSICAL_METADATA.map((item) => (
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

BatchEditAboutPhysicalMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  errors: PropTypes.object,
  register: PropTypes.func.isRequired,
  restProps: PropTypes.object,
};

export default BatchEditAboutPhysicalMetadata;
