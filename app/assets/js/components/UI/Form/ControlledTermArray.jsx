import { IconAdd, IconTrashCan } from "@js/components/Icon";

import { Button } from "@nulib/design-system";
import PropTypes from "prop-types";
import React from "react";
import UIFormControlledTermArrayItem from "./ControlledTermArrayItem";
import UIFormSelect from "./Select";
import { hasRole } from "@js/services/metadata";
import { useFieldArray } from "react-hook-form";
import { useFormContext } from "react-hook-form";

const UIFormControlledTermArray = ({
  authorities = [],
  label,
  name,
  roleDropdownOptions = [],
}) => {
  const {
    control,
    formState: { errors },
    register,
  } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name, // Metadata item form name
    keyName: "useFieldArrayId",
  });

  const needsRole = roleDropdownOptions.length > 0;

  function getRoleId({ role, roleId }) {
    if (!role && !roleId) return;
    return role ? role.id : roleId;
  }

  function getTermId({ term, termId }) {
    if (!term && !termId) return;
    return term ? term.id : termId;
  }

  function handleAddAnother() {
    const newField = { termId: "", label: "" };
    if (needsRole) newField.roleId = "";
    append(newField);
  }

  return (
    <>
      <ul className="mb-3">
        {fields.map((item, index) => {
          // Metadata item name combined with it's index in the array of multiple entries
          const itemName = `${name}[${index}]`;
          const isExistingFieldEntry = needsRole
            ? getRoleId(item) && getTermId(item)
            : getTermId(item);

          return (
            <li key={item.useFieldArrayId}>
              <fieldset>
                <legend
                  className="has-text-grey has-text-weight-light"
                  data-testid="legend"
                >{`${label} #${index + 1}`}</legend>

                {/* Existing values are NOT editable, so we save form data needed in the POST update, in hidden fields here */}
                {isExistingFieldEntry && (
                  <>
                    <p>
                      {item.term?.label || item.label} <br />
                      {getTermId(item)}
                      <br />
                      {item.role?.label ? item.role?.label : <>&nbsp;</>}
                    </p>
                    <input
                      type="hidden"
                      {...register(`${itemName}.termId`)}
                      value={getTermId(item)}
                    />
                    {getRoleId(item) && (
                      <input
                        type="hidden"
                        {...register(`${itemName}.roleId`)}
                        value={getRoleId(item) || null}
                      />
                    )}
                  </>
                )}

                {/* New form entries */}
                {!isExistingFieldEntry && (
                  <>
                    {hasRole(name) && (
                      <div className="field">
                        <label className="label">Role</label>
                        <UIFormSelect
                          hasErrors={
                            !!(errors[name] && errors[name][index]?.roleId)
                          }
                          isReactHookForm
                          name={`${itemName}.roleId`}
                          defaultValue={item.roleId}
                          label="Role"
                          options={roleDropdownOptions}
                          required
                          showHelper
                        />
                      </div>
                    )}

                    <UIFormControlledTermArrayItem
                      authorities={authorities}
                      item={item}
                      index={index}
                      label={label}
                      name={name}
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
                    <IconTrashCan />
                  </span>
                  <span>Remove</span>
                </button>
              </fieldset>
            </li>
          );
        })}
      </ul>

      <Button
        isLight
        onClick={handleAddAnother}
        data-testid="button-add-field-array-row"
      >
        <IconAdd />
        <span>Add {fields.length > 0 && "another"}</span>
      </Button>
    </>
  );
};

UIFormControlledTermArray.propTypes = {
  authorities: PropTypes.array,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  roleDropdownOptions: PropTypes.array,
};

export default UIFormControlledTermArray;
