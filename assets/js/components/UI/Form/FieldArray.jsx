import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";

const styles = {
  inputWrapper: {
    marginBottom: "1rem",
  },
  deleteButton: {
    marginLeft: "5px",
  },
};

const UIFormFieldArray = ({
  name,
  label,
  type = "text",
  errors,
  register,
  control,
  required,
  defaultValue = { value: `New ${label}` },
  ...passedInProps
}) => {
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });

  return (
    <fieldset {...passedInProps}>
      <legend data-testid="legend">{label}</legend>

      <ul style={styles.inputWrapper}>
        {fields.map((item, index) => {
          return (
            <li key={item.id} className="field">
              <>
                <div className="is-flex">
                  <input
                    name={`${[name]}[${index}].value`}
                    className="input"
                    defaultValue={`${item.value}`} // make sure to set up defaultValue
                    ref={register({ required })}
                    data-testid="input-field-array"
                  />
                  <button
                    type="button"
                    className="button"
                    onClick={() => remove(index)}
                    style={styles.deleteButton}
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
        <span>Add another</span>
      </button>
    </fieldset>
  );
};

UIFormFieldArray.propTypes = {
  name: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  control: PropTypes.object.isRequired,
};

export default UIFormFieldArray;
