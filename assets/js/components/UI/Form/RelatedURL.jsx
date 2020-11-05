import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import { isUrlValid } from "../../../services/helpers";
import { Button } from "@nulib/admin-react-components";
import { useFormContext } from "react-hook-form";

const UIFormRelatedURL = ({
  codeLists = [],
  label,
  name,
  required,
  ...passedInProps
}) => {
  const { control, errors, register } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name, // Metadata item form name
    keyName: "useFieldArrayId",
  });

  return (
    <div data-testid="related-url-wrapper">
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

                {/* Existing values are NOT editable, so we save form data needed in the POST update, in hidden fields here */}
                {!item.new && (
                  <div data-testid="related-url-existing-value">
                    <p>
                      {item.url}
                      {item.label && `, ${item.label.label}`}
                    </p>
                    <input
                      type="hidden"
                      name={`${itemName}.url`}
                      ref={register()}
                    />
                    <input
                      type="hidden"
                      name={`${itemName}.label`}
                      ref={register()}
                    />
                  </div>
                )}

                {/* New form entries */}
                {item.new && (
                  <div data-testid="related-url-form-item">
                    <div className="field">
                      <label className="label">URL</label>
                      <input
                        type="text"
                        name={`${itemName}.url`}
                        className={`input ${
                          errors[name] && errors[name][index].url
                            ? "is-danger"
                            : ""
                        }`}
                        ref={register({
                          required: "Related URL is required",
                          validate: (value) =>
                            isUrlValid(value) || "Please enter a valid URL",
                        })}
                        defaultValue=""
                        data-testid={`related-url-url-input`}
                      />
                      {errors[name] && errors[name][index].url && (
                        <p
                          data-testid={`relatedURL-input-errors-${index}`}
                          className="help is-danger"
                        >
                          {errors[name][index].url.message}
                        </p>
                      )}
                    </div>
                    <div className="field">
                      <UIFormSelect
                        isReactHookForm
                        name={`${itemName}.label`}
                        label="Label"
                        showHelper={true}
                        data-testid={`related-url-select`}
                        options={codeLists}
                        hasErrors={
                          !!(errors[name] && errors[name][index].label)
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
                  <span className="icon">
                    <FontAwesomeIcon icon="trash" />
                  </span>
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
          append({ new: true, url: "", label: "" });
        }}
        data-testid="button-add-field-array-row"
      >
        <span className="icon">
          <FontAwesomeIcon icon="plus" />
        </span>
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
