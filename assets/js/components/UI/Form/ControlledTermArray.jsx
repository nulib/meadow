import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import UIFormControlledTermArrayItem from "./ControlledTermArrayItem";
import { hasRole } from "../../../services/metadata";

const UIFormControlledTermArray = ({
  authorities = [],
  control,
  errors = {},
  label,
  name,
  register,
  required,
  roleDropdownOptions = [],
  ...passedInProps
}) => {
  const { fields, append, remove } = useFieldArray({
    control,
    name, // Metadata item form name
    keyName: "useFieldArrayId",
  });

  return (
    <>
      <ul className="mb-3">
        {fields.map((item, index) => {
          // Metadata item name combined with it's index in the array of multiple entries
          const itemName = `${name}[${index}]`;

          return (
            <li key={item.useFieldArrayId}>
              <fieldset>
                <legend
                  className="has-text-grey has-text-weight-light"
                  data-testid="legend"
                >{`${label} #${index + 1}`}</legend>

                {/* Existing values are NOT editable, so we save form data needed in the POST update, in hidden fields here */}
                {!item.new && (
                  <>
                    <p>
                      {item.term.label} {item.role && `(${item.role.label})`}
                    </p>
                    <input
                      type="hidden"
                      name={`${itemName}.termId`}
                      ref={register()}
                      value={item.term.id}
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

                {/* New form entries */}
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
                          defaultValue={item.roleId}
                          label="Role"
                          options={roleDropdownOptions}
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
                  className="button is-light is-small mt-3"
                  onClick={() => remove(index)}
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
          append({ new: true, termId: "", label: "", roleId: "" });
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
  authorities: PropTypes.array,
  control: PropTypes.object.isRequired,
  defaultValue: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  register: PropTypes.func,
  required: PropTypes.bool,
  roleDropdownOptions: PropTypes.array,
};

export default UIFormControlledTermArray;
