import React, { useState } from "react";
import PropTypes from "prop-types";
import { useFieldArray } from "react-hook-form";
import { useFormContext } from "react-hook-form";
import UIFormFieldArrayAddButton from "@js/components/UI/Form/FieldArrayAddButton";
import { isEDTFValid } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";

const UIFormBatchEDTFDate = ({
  name,
  label,
  type = "text",
  required,
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
    append({ metadataItem: "" });
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
                <>
                  <li className="field" key={item}>
                    <div className="is-flex">
                      <input
                        type="text"
                        name={`${[name]}[${index}].metadataItem`}
                        className={`input ${
                          errors[name] &&
                          errors[name][index] &&
                          errors[name][index].metadataItem
                            ? "is-danger"
                            : ""
                        }`}
                        ref={register({
                          required: "Date Created is required",
                          validate: (value) =>
                            isEDTFValid(value) || "Please enter a valid date",
                        })}
                        defaultValue=""
                        data-testid={`dateCreated-edtf-input`}
                      />
                      <Button
                        isText
                        onClick={() => handleRemoveClick(index)}
                        data-testid="button-delete-field-array-row"
                      >
                        <FontAwesomeIcon icon="trash" />
                      </Button>
                    </div>
                    {errors[name] &&
                      errors[name][index] &&
                      errors[name][index].metadataItem && (
                        <p
                          data-testid={`dateCreated-input-errors-${index}`}
                          className="help is-danger"
                        >
                          {errors[name][index].metadataItem.message}
                        </p>
                      )}
                  </li>
                </>
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

UIFormBatchEDTFDate.propTypes = {
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  required: PropTypes.bool,
  type: PropTypes.string,
  isTextarea: PropTypes.bool,
};

export default UIFormBatchEDTFDate;
