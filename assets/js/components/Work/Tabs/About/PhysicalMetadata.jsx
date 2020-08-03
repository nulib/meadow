import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import { PHYSICAL_METADATA } from "../../../../services/metadata";

const WorkTabsAboutPhysicalMetadata = ({
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  control,
}) => {
  return (
    <div className="columns is-multiline" data-testid="physical-metadata">
      {PHYSICAL_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray
              register={register}
              control={control}
              required
              name={item.name}
              label={item.label}
              errors={errors}
            />
          ) : (
            <UIFormFieldArrayDisplay
              items={descriptiveMetadata[item.name]}
              label={item.label}
            />
          )}
        </div>
      ))}
    </div>
  );
};

WorkTabsAboutPhysicalMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  register: PropTypes.func,
};

export default WorkTabsAboutPhysicalMetadata;
