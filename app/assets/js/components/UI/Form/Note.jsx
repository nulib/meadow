import React from "react";
import PropTypes from "prop-types";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import { Button } from "@nulib/design-system";
import { useFormContext } from "react-hook-form";
import { IconAdd, IconTrashCan } from "@js/components/Icon";

// Final shape of the Note input to API is
// note: { type: {id: "GENERAL_NOTE", scheme: "note_type"}, note: "Sample note" }

const UIFormNote = ({
  codeLists = [],
  label,
  name,
  required,
  ...passedInProps
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

  return (
    <div data-testid="note-wrapper">
      {errors[name] && (
        <p className="help is-danger">
          An issue has occured within <strong>Note</strong>. Verify entries for
          Note.
        </p>
      )}
      <ul className="mb-3">
        {fields.map((item, index) => {
          // Metadata item name combined with it's index in the array of multiple entries
          const itemName = `${name}[${index}]`;

          return (
            <li key={item.useFieldArrayId} data-testid={`note-list-item`}>
              <fieldset>
                <legend
                  className="has-text-grey has-text-weight-light"
                  data-testid="legend"
                >{`${label} #${index + 1}`}</legend>

                {/* 
                Existing values are NOT editable, so we save form data needed in the POST update, in hidden fields here 
                item.label - comes from the API as a previously existing value
                item.typeId is a new entry in the form  
                */}

                {(item.type || item.typeId) && (
                  <div data-testid="note-existing-value">
                    <p>
                      {item.note}
                      {item.type && `, ${item.type.label}`}
                    </p>
                    <input
                      type="hidden"
                      name={`${itemName}.note`}
                      {...register(`${itemName}.note`)}
                      value={item.note}
                    />
                    <input
                      type="hidden"
                      name={`${itemName}.typeId`}
                      {...register(`${itemName}.typeId`)}
                      value={item.type ? item.type.id : ""}
                    />
                  </div>
                )}

                {/* New form entries */}
                {!item.typeId && !item.type && (
                  <div data-testid="note-form-item">
                    <div className="field">
                      <label className="label">Note</label>
                      <input
                        type="text"
                        name={`${itemName}.note`}
                        className={`input ${
                          errors[name] &&
                          errors[name][index] &&
                          errors[name][index].note
                            ? "is-danger"
                            : ""
                        }`}
                        {...register(`${itemName}.note`, {
                          required: "Note is required",
                        })}
                        defaultValue=""
                        data-testid={`note-input`}
                      />
                      {errors[name] &&
                        errors[name][index] &&
                        errors[name][index].note && (
                          <p
                            data-testid={`note-input-errors-${index}`}
                            className="help is-danger"
                          >
                            {errors[name][index].note.message}
                          </p>
                        )}
                    </div>
                    <div className="field">
                      <label className="label">Note Type</label>
                      <UIFormSelect
                        isReactHookForm
                        name={`${itemName}.typeId`}
                        label="Note Type"
                        showHelper={true}
                        data-testid={`note-select`}
                        options={codeLists}
                        hasErrors={
                          !!(
                            errors[name] &&
                            errors[name][index] &&
                            errors[name][index].typeId
                          )
                        }
                        required
                      />
                    </div>
                  </div>
                )}

                <Button
                  type="button"
                  className="button is-light is-small mt-3"
                  onClick={() => remove(index)}
                  data-testid={`button-note-remove`}
                >
                  <IconTrashCan />
                  <span>Remove</span>
                </Button>
              </fieldset>
            </li>
          );
        })}
      </ul>

      <Button
        isLight
        onClick={() => {
          append({ note: "", typeId: "" });
        }}
        data-testid="button-add-field-array-row"
      >
        <IconAdd />
        <span>Add {fields.length > 0 && "another"}</span>
      </Button>
    </div>
  );
};

UIFormNote.propTypes = {
  codeLists: PropTypes.array,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  roleDropdownOptions: PropTypes.array,
};

export default UIFormNote;
