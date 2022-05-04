import React from "react";
import PropTypes from "prop-types";
import { PROJECT_METADATA } from "@js/services/metadata";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormInput from "@js/components/UI/Form/Input";

const BatchEditAdministrativeProjectMetadata = ({ ...restProps }) => {
  return (
    <div data-testid="project-metadata" {...restProps}>
      {PROJECT_METADATA.map((item) => (
        // <div key={item.name} data-testid={item.name}>
        //   <UIFormBatchFieldArray required name={item.name} label={item.label} />
        // </div>
        <UIFormField key={item.name} label={item.label}>
          <UIFormInput
            data-testid={item.name}
            isReactHookForm
            placeholder={item.label}
            name={item.name}
            label={item.label}
          />
        </UIFormField>
      ))}

      <UIFormField label="Project Cycle" data-testid="projectCycle">
        <UIFormInput
          data-testid="project-cycle"
          isReactHookForm
          placeholder="Project Cycle"
          name="projectCycle"
          label="Project Cycle"
        />
      </UIFormField>
    </div>
  );
};

BatchEditAdministrativeProjectMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAdministrativeProjectMetadata;
