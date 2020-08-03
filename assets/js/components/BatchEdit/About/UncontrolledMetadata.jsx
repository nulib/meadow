import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import { UNCONTROLLED_METADATA } from "../../../services/metadata";

const BatchEditAboutUncontrolledMetadata = ({
  control,
  errors,
  register,
  ...restProps
}) => {
  return (
    <div
      className="columns is-multiline"
      data-testid="uncontrolled-metadata"
      {...restProps}
    >
      {UNCONTROLLED_METADATA.map((item) => (
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

BatchEditAboutUncontrolledMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  errors: PropTypes.object,
  register: PropTypes.func.isRequired,
  restProps: PropTypes.object,
};

export default BatchEditAboutUncontrolledMetadata;
