import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import UIFormControlledTermArrayItem from "./ControlledTermArrayItem";
import { hasRole } from "../../../services/metadata";

const styles = {
  inputWrapper: {
    marginBottom: "1rem",
  },
  deleteButton: {
    marginTop: "1rem",
  },
};

const UIFormControlledTermArray = ({
  codeLists: { authorities = [], marcRelators = [] },
  control,
  errors = {},
  label,
  name,
  register,
  required,
  ...passedInProps
}) => {
  const { fields, append, remove } = useFieldArray({
    control,
    name,
  });

  return (
    <>
      <ul style={styles.inputWrapper}>
        {fields.map((item, index) => {
          const itemName = `${name}[${index}]`;

          return (
            <li key={item.id}>
              <fieldset>
                <legend
                  className="has-text-grey has-text-weight-light"
                  data-testid="legend"
                >{`${label} #${index + 1}`}</legend>

                {/* Existing values are NOT editable, so we save them in hidden fields */}
                {!item.new && (
                  <>
                    <p>
                      {item.label} {item.role && `(${item.role.label})`}
                    </p>
                    <input
                      type="hidden"
                      name={`${itemName}.id`}
                      ref={register()}
                      value={item.id}
                    />
                    {item.role && (
                      <input
                        type="hidden"
                        name={`${itemName}.roleId`}
                        ref={register()}
                        value={item.role ? item.role.id : null}
                      />
                    )}
                  </>
                )}

                {item.new && (
                  <>
                    {hasRole(name) && (
                      <div className="field">
                        <label className="label">Role</label>
                        <UIFormSelect
                          hasErrors={
                            !!(errors[name] && errors[name][index].roleId)
                          }
                          name={`${itemName}.roleId`}
                          label="Role"
                          options={marcRelators}
                          register={register}
                          required
                          showHelper
                        />
                      </div>
                    )}

                    <UIFormControlledTermArrayItem
                      authorities={authorities}
                      control={control}
                      errors={errors}
                      item={item}
                      index={index}
                      label={label}
                      name={name}
                      register={register}
                    />
                  </>
                )}

                <button
                  type="button"
                  className="button is-light is-small"
                  onClick={() => remove(index)}
                  style={styles.deleteButton}
                  data-testid="button-delete-field-array-row"
                >
                  <span className="icon">
                    <FontAwesomeIcon icon="trash" />
                  </span>
                  <span>Remove</span>
                </button>
              </fieldset>
            </li>
          );
        })}
      </ul>

      <button
        type="button"
        className="button is-text is-small"
        onClick={() => {
          append({ new: true });
        }}
        data-testid="button-add-field-array-row"
      >
        <span className="icon">
          <FontAwesomeIcon icon="plus" />
        </span>
        <span>Add {fields.length > 0 && "another"}</span>
      </button>
    </>
  );
};

UIFormControlledTermArray.propTypes = {
  codeLists: PropTypes.shape({
    authorities: PropTypes.array,
    marcRelators: PropTypes.array,
  }),
  control: PropTypes.object.isRequired,
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  register: PropTypes.func,
  required: PropTypes.bool,
};

export default UIFormControlledTermArray;
