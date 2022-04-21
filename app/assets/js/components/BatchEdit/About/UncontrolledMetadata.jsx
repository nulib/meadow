import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import UIFormBatchFieldArray from "@js/components/UI/Form/BatchFieldArray";
import { UNCONTROLLED_METADATA } from "@js/services/metadata";
import UIFormNote from "@js/components/UI/Form/Note";
import { useCodeLists } from "@js/context/code-list-context";

const BatchEditAboutUncontrolledMetadata = ({ ...restProps }) => {
  const codeLists = useCodeLists();

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
      <div className="column is-full" data-testid="notes">
        <fieldset data-testid="batch-field-array">
          <legend data-testid="legend">Notes</legend>
          <UIFormField label="Notes">
            <UIFormNote
              codeLists={
                codeLists.notesData ? codeLists.notesData.codeList : []
              }
              label="Notes"
              name="notes"
            />
            <UIFormSelect
              isReactHookForm
              name="notes--editType"
              data-testid="select-edit-type"
              options={[
                { id: "append", label: "Append values" },
                { id: "replace", label: "Replace existing values" },
                { id: "delete", label: "Delete all values" },
              ]}
            ></UIFormSelect>
          </UIFormField>
        </fieldset>
      </div>
    </div>
  );
};

BatchEditAboutUncontrolledMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutUncontrolledMetadata;
