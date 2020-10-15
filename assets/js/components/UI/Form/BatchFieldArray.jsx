import React, { useState } from "react";
import PropTypes from "prop-types";
import { useFieldArray } from "react-hook-form";
import { useFormContext } from "react-hook-form";
import UIFormFieldArrayRow from "@js/components/UI/Form/FieldArrayRow";
import UIFormFieldArrayAddButton from "@js/components/UI/Form/FieldArrayAddButton";

const UIFormBatchFieldArray = ({
  name,
  label,
  type = "text",
  required,
  defaultValue = `New ${label}`,
  ...passedInProps
}) => {
  const { control, errors, register } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });
  const [isReplace, setIsReplace] = useState();
  const [isRemove, setIsRemove] = useState();

  function handleAddClick() {
    append({ metadataItem: defaultValue });
  }

  function handleRemoveClick(index) {
    remove(index);
  }

  return (
    <fieldset {...passedInProps}>
      <legend data-testid="legend">{label}</legend>

      {!isRemove && (
        <>
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
                />
              );
            })}
          </ul>

          <UIFormFieldArrayAddButton
            btnLabel={`Add ${fields.length > 0 ? "another" : ""}`}
            handleAddClick={handleAddClick}
          />

          <div className="field mt-3">
            <input
              className="is-checkradio"
              id={`${name}--replaceCheckbox`}
              type="checkbox"
              name={`${name}--replaceCheckbox`}
              onChange={() => setIsReplace(!isReplace)}
              ref={register()}
            />
            <label
              className="has-text-grey"
              htmlFor={`${name}--replaceCheckbox`}
            >
              Replace values
            </label>
          </div>
        </>
      )}

      <div className="field">
        <input
          className="is-checkradio"
          id={`${name}--removeCheckbox`}
          type="checkbox"
          name={`${name}--removeCheckbox`}
          onChange={() => setIsRemove(!isRemove)}
          ref={register()}
        />
        <label className="has-text-grey" htmlFor={`${name}--removeCheckbox`}>
          Remove all values
        </label>
      </div>
    </fieldset>
  );
};

UIFormBatchFieldArray.propTypes = {
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  required: PropTypes.bool,
  type: PropTypes.string,
};

export default UIFormBatchFieldArray;
