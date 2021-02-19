import React from "react";
import PropTypes from "prop-types";
import { useFieldArray } from "react-hook-form";
import { useFormContext } from "react-hook-form";
import UIFormFieldArrayRow from "@js/components/UI/Form/FieldArrayRow";
import UIFormFieldArrayAddButton from "@js/components/UI/Form/FieldArrayAddButton";
import UIFormSelect from "@js/components/UI/Form/Select";
import UIFormField from "@js/components/UI/Form/Field";

const UIFormBatchFieldArray = ({
  name,
  label,
  type = "text",
  required,
  defaultValue = `New ${label}`,
  isTextarea,
  validateFn,
  ...passedInProps
}) => {
  const { control } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });
  const [isDelete, setIsDelete] = React.useState();

  function handleAddClick() {
    append({ metadataItem: "" });
  }

  function handleChangeEditType(e) {
    setIsDelete(e.target.value === "delete");
  }

  function handleRemoveClick(index) {
    remove(index);
  }

  return (
    <fieldset data-testid="batch-field-array" {...passedInProps}>
      <legend data-testid="legend">{label}</legend>

      <ul
        className={`mb-4 ${isDelete ? "is-hidden" : ""}`}
        data-testid="fields-list"
      >
        {fields.map((item, index) => {
          return (
            <UIFormFieldArrayRow
              key={item.id}
              handleRemoveClick={handleRemoveClick}
              item={item}
              index={index}
              label={label}
              name={name}
              isTextarea={isTextarea}
              validateFn={validateFn}
            />
          );
        })}
      </ul>

      {!isDelete && (
        <UIFormFieldArrayAddButton
          btnLabel={`Add ${fields.length > 0 ? "another" : ""}`}
          handleAddClick={handleAddClick}
        />
      )}

      <UIFormField>
        <UIFormSelect
          isReactHookForm
          name={`${name}--editType`}
          data-testid="select-edit-type"
          onChange={handleChangeEditType}
          options={[
            { id: "append", label: "Append values" },
            { id: "replace", label: "Replace existing values" },
            { id: "delete", label: "Delete all values" },
          ]}
        ></UIFormSelect>
      </UIFormField>
    </fieldset>
  );
};

UIFormBatchFieldArray.propTypes = {
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  required: PropTypes.bool,
  type: PropTypes.string,
  isTextarea: PropTypes.bool,
  validateFn: PropTypes.func,
};

export default UIFormBatchFieldArray;
