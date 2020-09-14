import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";

const UIFormFieldArray = ({
  name,
  label,
  type = "text",
  errors = {},
  register,
  control,
  required,
  defaultValue = `New ${label}`,
  mocked,
  notLive,
  ...passedInProps
}) => {
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });

  return (
    <fieldset {...passedInProps}>
      <legend data-testid="legend">
        {label} {mocked && <span className="tag">Mocked</span>}{" "}
        {notLive && <span className="tag">Not Live</span>}
      </legend>

      <ul className="mb-4">
        {fields.map((item, index) => {
          return (
            <li key={item.id} className="field">
              <>
                <div className="is-flex">
                  <input
                    name={`${[name]}[${index}].name`}
                    className={`input ${
                      errors[name] && errors[name][index] ? "is-danger" : ""
                    }`}
                    defaultValue={item.value} // make sure to set up defaultValue
                    ref={register({ required })}
                    data-testid="input-field-array"
                  />
                  <button
                    type="button"
                    className="button ml-1"
                    onClick={() => remove(index)}
                    data-testid="button-delete-field-array-row"
                  >
                    <FontAwesomeIcon icon="trash" />
                  </button>
                </div>
                {errors[name] && errors[name][index] && (
                  <p data-testid="input-errors" className="help is-danger">
                    {label || name} field is required
                  </p>
                )}
              </>
            </li>
          );
        })}
      </ul>

      <button
        type="button"
        className="button is-text is-small"
        onClick={() => {
          append(defaultValue);
        }}
        data-testid="button-add-field-array-row"
      >
        <span className="icon">
          <FontAwesomeIcon icon="plus" />
        </span>
        <span>Add {fields.length > 0 && "another"}</span>
      </button>
    </fieldset>
  );
};

UIFormFieldArray.propTypes = {
  control: PropTypes.object.isRequired,
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  mocked: PropTypes.bool,
  name: PropTypes.string.isRequired,
  notLive: PropTypes.bool,
  register: PropTypes.func,
  required: PropTypes.bool,
  type: PropTypes.string,
};

export default UIFormFieldArray;
