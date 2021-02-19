import React from "react";
import PropTypes from "prop-types";
import { useFieldArray } from "react-hook-form";
import { useFormContext } from "react-hook-form";
import UIFormFieldArrayRow from "@js/components/UI/Form/FieldArrayRow";
import UIFormFieldArrayAddButton from "@js/components/UI/Form/FieldArrayAddButton";

const UIFormFieldArray = ({
  name,
  label,
  type = "text",
  required,
  defaultValue = `New ${label}`,
  mocked,
  notLive,
  isTextarea,
  validateFn,
  ...passedInProps
}) => {
  const { control } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });

  function handleAddClick() {
    append({ metadataItem: "" });
  }

  function handleRemoveClick(index) {
    remove(index);
  }

  return (
    <fieldset {...passedInProps}>
      <legend data-testid="legend">
        {label} {mocked && <span className="tag">Mocked</span>}{" "}
        {notLive && <span className="tag">Not Live</span>}
      </legend>

      <ul className="mb-4">
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

      <UIFormFieldArrayAddButton
        btnLabel={`Add ${fields.length > 0 ? "another" : ""}`}
        handleAddClick={handleAddClick}
      />
    </fieldset>
  );
};

UIFormFieldArray.propTypes = {
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  mocked: PropTypes.bool,
  name: PropTypes.string.isRequired,
  notLive: PropTypes.bool,
  required: PropTypes.bool,
  type: PropTypes.string,
  isTextarea: PropTypes.bool,
  validateFn: PropTypes.func,
};

export default UIFormFieldArray;
