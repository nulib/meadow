import React from "react";
import PropTypes from "prop-types";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import { isUrlValid } from "../../../services/helpers";
import { Button } from "@nulib/design-system";
import { useFormContext } from "react-hook-form";
import { IconAdd, IconTrashCan } from "@js/components/Icon";

// Final shape of the Related URL input to API is
// relatedUrl: { label: { id: "ABC123", scheme: "RELATED_URL" }, url: "http://yo.com"}

const UIFormRelatedURL = ({
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
    <div data-testid="related-url-wrapper">
      {errors[name] && (
        <p className="help is-danger">
          An issue has occured within <strong>Related URL</strong>. Verify
          entries for Related URL.
        </p>
      )}
      <ul className="mb-3">
        {fields.map((item, index) => {
          // Metadata item name combined with it's index in the array of multiple entries
          const itemName = `${name}[${index}]`;

          return (
            <li
              key={item.useFieldArrayId}
              data-testid={`related-url-list-item`}
            >
              <fieldset>
                <legend
                  className="has-text-grey has-text-weight-light"
                  data-testid="legend"
                >{`${label} #${index + 1}`}</legend>

                {/* 
                Existing values are NOT editable, so we save form data needed in the POST update, in hidden fields here 
                item.label - comes from the API as a previously existing value
                item.labelId is a new entry in the form  
                */}

                {(item.label || item.labelId) && (
                  <div data-testid="related-url-existing-value">
                    <p>
                      {item.url}
                      {item.label && `, ${item.label.label}`}
                    </p>
                    <input
                      type="hidden"
                      name={`${itemName}.url`}
                      {...register(`${itemName}.url`)}
                      value={item.url}
                    />
                    <input
                      type="hidden"
                      name={`${itemName}.labelId`}
                      {...register(`${itemName}.labelId`)}
                      value={item.label ? item.label.id : ""}
                    />
                  </div>
                )}

                {/* New form entries */}
                {!item.labelId && !item.label && (
                  <div data-testid="related-url-form-item">
                    <div className="field">
                      <label className="label">URL</label>
                      <input
                        type="text"
                        name={`${itemName}.url`}
                        className={`input ${
                          errors[name] &&
                          errors[name][index] &&
                          errors[name][index].url
                            ? "is-danger"
                            : ""
                        }`}
                        {...register(`${itemName}.url`, {
                          required: "Related URL is required",
                          validate: (value) =>
                            isUrlValid(value) || "Please enter a valid URL",
                        })}
                        defaultValue=""
                        data-testid={`related-url-url-input`}
                      />
                      {errors[name] &&
                        errors[name][index] &&
                        errors[name][index].url && (
                          <p
                            data-testid={`relatedURL-input-errors-${index}`}
                            className="help is-danger"
                          >
                            {errors[name][index].url.message}
                          </p>
                        )}
                    </div>
                    <div className="field">
                      <label className="label">Label</label>
                      <UIFormSelect
                        isReactHookForm
                        name={`${itemName}.labelId`}
                        label="Label"
                        showHelper={true}
                        data-testid={`related-url-select`}
                        options={codeLists}
                        hasErrors={
                          !!(
                            errors[name] &&
                            errors[name][index] &&
                            errors[name][index].labelId
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
                  data-testid={`button-related-url-remove`}
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
          append({ url: "", labelId: "" });
        }}
        data-testid="button-add-field-array-row"
      >
        <IconAdd />
        <span>Add {fields.length > 0 && "another"}</span>
      </Button>
    </div>
  );
};

UIFormRelatedURL.propTypes = {
  codeLists: PropTypes.array,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  roleDropdownOptions: PropTypes.array,
};

export default UIFormRelatedURL;
