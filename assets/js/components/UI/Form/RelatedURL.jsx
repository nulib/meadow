import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import UIInput from "./Input";

const UIFormRelatedURL = ({
  codeLists = [],
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
                      {item.url}
                      {item.label && `, ${item.label.label}`}
                    </p>
                    <input
                      type="hidden"
                      name={`${itemName}.url`}
                      ref={register()}
                      value={item.url}
                    />
                    <input
                      type="hidden"
                      name={`${itemName}.label`}
                      ref={register()}
                      value={item.label.id}
                    />
                  </>
                )}

                {/* New form entries */}
                {item.new && (
                  <>
                    <div className="field">
                      <label className="label">URL</label>
                      <UIInput
                        register={register}
                        name={`${itemName}.url`}
                        label="URL"
                        data-testid="url"
                        errors={errors}
                      />
                    </div>
                    <div className="field">
                      <UIFormSelect
                        register={register}
                        name={`${itemName}.label`}
                        label="Label"
                        showHelper={true}
                        data-testid="label"
                        options={codeLists}
                        errors={errors}
                        required
                      />
                    </div>
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
          append({ new: true, url: "", label: "" });
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

UIFormRelatedURL.propTypes = {
  codeLists: PropTypes.array,
  control: PropTypes.object.isRequired,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  register: PropTypes.func,
  roleDropdownOptions: PropTypes.array,
};

export default UIFormRelatedURL;
