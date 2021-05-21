import React from "react";
import PropTypes from "prop-types";
import UIInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormBatchFieldArray from "@js/components/UI/Form/BatchFieldArray";
import { useFormContext } from "react-hook-form";
import { useCodeLists } from "@js/context/code-list-context";
import { isEDTFValid } from "@js/services/helpers";

const BatchEditAboutCoreMetadata = ({ ...restProps }) => {
  const codeLists = useCodeLists();
  const context = useFormContext();
  const register = context.register;
  const EDTFValidateFn = (value) => {
    return (
      isEDTFValid(value) || (
        <span>
          Please enter a{" "}
          <a href="https://www.loc.gov/standards/datetime/" target="_blank">
            valid EDTF date
          </a>
        </span>
      )
    );
  };
  return (
    <div
      className="columns is-multiline"
      data-testid="core-metadata"
      {...restProps}
    >
      <div className="column is-two-thirds">
        {/* Title */}
        <UIFormField label="Title">
          <UIInput
            isReactHookForm
            name="title"
            label="Title"
            data-testid="title"
          />
        </UIFormField>
      </div>

      <div className="column is-half">
        {/* Alternate Title */}
        <UIFormBatchFieldArray
          name="alternateTitle"
          data-testid="alternate-title"
          label="Alternate Title"
        />
      </div>

      <div className="column is-half">
        {/* Description */}
        <UIFormBatchFieldArray
          name="description"
          label="Description"
          data-testid="description"
          isTextarea={true}
        />
      </div>

      <div className="column is-half">
        {/* Date Created */}
        <UIFormBatchFieldArray
          name="dateCreated"
          label="Date Created"
          data-testid="date-created"
          validateFn={EDTFValidateFn}
        />
      </div>

      <div className="column is-full">
        <UIFormField label="Rights Statement">
          <div className="select" data-testid="rights-statement">
            <select {...register("rightsStatement")}>
              <option value="">-- Select --</option>
              {codeLists.rightsStatementData &&
                codeLists.rightsStatementData.codeList.map((item) => (
                  <option
                    key={item.id}
                    value={JSON.stringify({
                      id: item.id,
                      scheme: "RIGHTS_STATEMENT",
                      label: item.label,
                    })}
                  >
                    {item.label}
                  </option>
                ))}
            </select>
          </div>
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutCoreMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutCoreMetadata;
