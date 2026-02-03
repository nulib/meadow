import {
  prepFieldArrayItemsForPost,
  prepNotes,
  prepRelatedUrl,
  prepControlledTermInput,
  CONTROLLED_METADATA,
} from "@js/services/metadata";
import { isCodedTerm, isTextSingle, isTextArray } from "@js/components/Plan/Panel/diff-helpers";

import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { useForm, FormProvider } from "react-hook-form";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormSelect from "@js/components/UI/Form/Select";
import UIFormNote from "@js/components/UI/Form/Note";
import UIFormRelatedURL from "@js/components/UI/Form/RelatedURL";
import UIFormControlledTermArray from "@js/components/UI/Form/ControlledTermArray";
import { useCodeLists } from "@js/context/code-list-context";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const noBullets = css`
  ul {
    list-style: none;
    padding-left: 0;
  }
`;

const EditDiffRowForm = ({ change, isOpen, onSave, onCancel }) => {
  const codeLists = useCodeLists();

  console.log("EditDiffRowForm - change:", change);
  console.log(
    "EditDiffRowForm - change (stringified):",
    JSON.stringify(change, null, 2),
  );

  if (!change) return null;

  const fieldType = {
    isControlled: change.controlled,
    isNestedCoded: change.nestedCoded,
    isCoded: isCodedTerm(change.path),
    isPlainTextArray: isTextArray(change.path),
    isPlainTextSingle: isTextSingle(change.path),
  };

  // Check if this field type is supported for editing
  const isSupported = Object.values(fieldType).some(v => v);

  // Get controlled field metadata if applicable
  const controlledFieldMeta = fieldType.isControlled
    ? CONTROLLED_METADATA.find((f) => change.path.endsWith(f.name))
    : null;

  // Get the form field name for controlled terms (use actual field name, not "values")
  const controlledFieldName = controlledFieldMeta?.name || "values";

  // Helper to safely get a code list by key
  const getCodeList = (key) => codeLists[key]?.codeList || [];

  // Get role dropdown options based on field scheme
  const getRoleDropdownOptions = (fieldMeta) => {
    if (!fieldMeta) return [];
    if (fieldMeta.scheme === "MARC_RELATOR") {
      return getCodeList("marcData");
    } else if (fieldMeta.scheme === "SUBJECT_ROLE") {
      return getCodeList("subjectRoleData");
    }
    return [];
  };

  // Parser functions for converting values from form data to API format
  const parsers = {
    plainTextArray: (data) => prepFieldArrayItemsForPost(data.values),

    coded: (data) => {
      const selectedId = data.value;
      const fieldName = change.path.split(".").pop();
      const codeListKey = fieldName + "Data";
      const codeList = getCodeList(codeListKey);
      const selectedItem = codeList.find((item) => item.id === selectedId);

      if (selectedItem) {
        return {
          id: selectedItem.id,
          label: selectedItem.label,
          scheme: selectedItem.scheme,
        };
      }
      return change.value; // Keep original if not found
    },

    nestedCoded: (data) => {
      if (change.path.endsWith("notes")) {
        return prepNotes(data.values);
      } else if (change.path.endsWith("related_url")) {
        return prepRelatedUrl(data.values);
      }
      return data.values;
    },

    controlled: (data) => {
      // return prepControlledTermInput(controlledFieldMeta, data[controlledFieldName]);
      const result = prepControlledTermInput(controlledFieldMeta, data[controlledFieldName]);
      // Transform from { term: "url" } to { term: { id: "url" } }
      return result.map(item => ({
        ...item,
        term: { id: item.term }
      }));
    },

    plainTextSingle: (data) => data.value,
  };

  // Get default values for React Hook Form based on field type
  const getDefaultValues = () => {
    if (fieldType.isPlainTextArray) {
      // UIFormFieldArray expects array of { metadataItem: "value" }
      return {
        values: change.value.map((v) => ({ metadataItem: v })),
      };
    } else if (fieldType.isCoded) {
      // Coded terms: just use the id (URL)
      return { value: change.value?.id || "" };
    } else if (fieldType.isNestedCoded) {
      // Nested coded terms (notes, related_url): pass the array as-is
      return { values: change.value || [] };
    } else if (fieldType.isControlled) {
      // Controlled terms: use actual field name
      return { [controlledFieldName]: change.value || [] };
    } else {
      // Single text field
      return { value: change.value || "" };
    }
  };

  const defaultValues = getDefaultValues();

  const methods = useForm({
    defaultValues: defaultValues,
  });
  const { isDirty } = methods.formState;

  // Reset form with defaultValues when change prop updates
  React.useEffect(() => {
    methods.reset(defaultValues);
  }, [change?.id]);

  const onSubmit = (data) => {
    console.log("onSubmit row data: ", data);
    console.log("onSubmit row data (string): ", JSON.stringify(data, null, 2));

    // Determine which parser to use based on field type
    const parserKey = fieldType.isPlainTextArray ? 'plainTextArray'
      : fieldType.isCoded ? 'coded'
      : fieldType.isNestedCoded ? 'nestedCoded'
      : fieldType.isControlled ? 'controlled'
      : 'plainTextSingle';

    const parsedValue = parsers[parserKey](data);

    onSave(change.id, parsedValue);
    methods.reset();
  };

  return (
    <FormProvider {...methods}>
      <form
        name="modal-edit-plan-change"
        data-testid="modal-edit-plan-change"
        className={`modal ${isOpen ? "is-active" : ""}`}
        onSubmit={methods.handleSubmit(onSubmit)}
        role="form"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">
              Edit {change.method} - {change.label}
            </p>
            <button
              className="delete"
              aria-label="close"
              type="button"
              onClick={onCancel}
            ></button>
          </header>
          <section className="modal-card-body">
            {!isSupported ? (
              <div className="notification is-warning">
                <p>
                  <strong>Editing this field type is not yet supported.</strong>
                </p>
                <p>
                  {fieldType.isControlled && "This is a controlled vocabulary field."}
                  {fieldType.isNestedCoded &&
                    " This is a structured field with nested data."}
                </p>
                <p className="mt-3">Supported field types:</p>
                <ul>
                  <li>• Single-valued text fields (e.g., title)</li>
                  <li>
                    • Multi-valued text fields (e.g., description,
                    alternate_title)
                  </li>
                  <li>• Coded term fields (e.g., license, rights_statement)</li>
                  <li>• Nested coded fields (e.g., notes, related_url)</li>
                  <li>• Controlled vocabulary fields (e.g., subject, genre, contributor)</li>
                </ul>
              </div>
            ) : fieldType.isPlainTextArray ? (
              <div css={noBullets}>
                <UIFormFieldArray
                  name="values"
                  label={change.label}
                  required
                  isTextarea={true}
                />
              </div>
            ) : fieldType.isCoded ? (
              <UIFormField label={change.label}>
                <UIFormSelect
                  isReactHookForm
                  name="value"
                  label={change.label}
                  showHelper={true}
                  options={(() => {
                    const fieldName = change.path.split(".").pop();
                    const codeListKey = fieldName + "Data";
                    return getCodeList(codeListKey);
                  })()}
                  defaultValue={change.value ? change.value.id : ""}
                />
              </UIFormField>
            ) : fieldType.isNestedCoded ? (
              <div css={noBullets}>
                <UIFormField label={change.label}>
                  {change.path.endsWith("notes") ? (
                    <UIFormNote
                      codeLists={getCodeList("notesData")}
                      label={change.label}
                      name="values"
                    />
                  ) : change.path.endsWith("related_url") ? (
                    <UIFormRelatedURL
                      codeLists={getCodeList("relatedUrlData")}
                      label={change.label}
                      name="values"
                    />
                  ) : null}
                </UIFormField>
              </div>
            ) : fieldType.isControlled ? (
              <div css={noBullets}>
                <UIFormField label={change.label}>
                  <UIFormControlledTermArray
                    authorities={getCodeList("authorityData")}
                    roleDropdownOptions={getRoleDropdownOptions(controlledFieldMeta)}
                    label={change.label}
                    name={controlledFieldName}
                  />
                </UIFormField>
              </div>
            ) : (
              <UIFormField label="Value" forId="edit-value" required>
                <UIFormInput
                  isReactHookForm
                  required
                  id="edit-value"
                  name="value"
                  label="Value"
                  placeholder="Enter value"
                />
              </UIFormField>
            )}
          </section>
          <footer className="modal-card-foot buttons is-right">
            <Button isText onClick={onCancel} data-testid="cancel-button">
              Cancel
            </Button>
            {isSupported && (
              <Button
                isPrimary
                type="submit"
                data-testid="submit-button"
                disabled={!isDirty}
              >
                Save changes
              </Button>
            )}
          </footer>
        </div>
      </form>
    </FormProvider>
  );
};

EditDiffRowForm.propTypes = {
  change: PropTypes.object,
  isOpen: PropTypes.bool,
  onSave: PropTypes.func,
  onCancel: PropTypes.func,
};

export default EditDiffRowForm;
