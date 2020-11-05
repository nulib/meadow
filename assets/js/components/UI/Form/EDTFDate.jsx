import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
import UIFormSelect from "./Select";
import { isEDTFValid } from "../../../services/helpers";
import { Button } from "@nulib/admin-react-components";
import { useFormContext } from "react-hook-form";

const UIFormEDTFDate = ({ label, name, required, ...passedInProps }) => {
  const { control, errors, register } = useFormContext();
  const { fields, append, remove } = useFieldArray({
    control,
    name, // Metadata item form name
    keyName: "useFieldArrayId",
  });

  return (
    <div data-testid="dateCreated-wrapper">
      <ul className="mb-3">
        {fields.map((item, index) => {
          // Metadata item name combined with it's index in the array of multiple entries
          const itemName = `${name}[${index}]`;

          return (
            <li
              key={item.useFieldArrayId}
              data-testid={`dateCreated-list-item`}
            >
              <fieldset>
                <legend
                  className="has-text-grey has-text-weight-light"
                  data-testid="legend"
                >{`Created Date #${index + 1}`}</legend>

                {/* Existing values are NOT editable, so we save form data needed in the POST update, in hidden fields here */}
                {!item.new && (
                  <div data-testid="dateCreated-existing-value">
                    <p>{item.humanized}</p>
                    <input
                      type="hidden"
                      name={`${itemName}.edtf`}
                      ref={register()}
                      defaultValue={item.edtf}
                    />
                  </div>
                )}

                {/* New form entries */}
                {item.new && (
                  <div data-testid="dateCreated-form-item">
                    <div className="field">
                      <label className="label">Date</label>
                      <input
                        type="text"
                        name={`${itemName}.edtf`}
                        className={`input ${
                          errors[name] &&
                          errors[name][index] &&
                          errors[name][index].edtf
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
                      {errors[name] &&
                        errors[name][index] &&
                        errors[name][index].edtf && (
                          <p
                            data-testid={`dateCreated-input-errors-${index}`}
                            className="help is-danger"
                          >
                            {errors[name][index].edtf.message}
                          </p>
                        )}
                    </div>
                  </div>
                )}

                <Button
                  type="button"
                  className="button is-light is-small mt-3"
                  onClick={() => remove(index)}
                  data-testid={`button-dateCreated-remove`}
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
        type="button"
        className="button is-text is-small"
        onClick={() => {
          append({ new: true, edtf: "" });
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

UIFormEDTFDate.propTypes = {
  options: PropTypes.array,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
};

export default UIFormEDTFDate;
