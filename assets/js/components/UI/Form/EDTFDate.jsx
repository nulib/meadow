import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useFieldArray } from "react-hook-form";
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
      <fieldset>
        <legend data-testid="legend">Date Created</legend>

        <ul className="mb-3">
          {fields.map((item, index) => {
            // Metadata item name combined with it's index in the array of multiple entries
            const itemName = `${name}[${index}]`;

            return (
              <li
                key={item.useFieldArrayId}
                data-testid={`dateCreated-list-item`}
                className="field"
              >
                <div className="field" data-testid="dateCreated-form-item">
                  <div className="is-flex">
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
                      defaultValue={item.edtf}
                      data-testid={`dateCreated-edtf-input`}
                    />
                    <Button
                      isText
                      onClick={() => remove(index)}
                      data-testid={`button-dateCreated-remove`}
                    >
                      <FontAwesomeIcon icon="trash" />
                    </Button>
                  </div>
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
              </li>
            );
          })}
        </ul>

        <Button
          type="button"
          className="button is-light"
          onClick={() => {
            append({ new: true, edtf: "" });
          }}
          data-testid="button-add-field-array-row"
        >
          <span className="icon">
            <FontAwesomeIcon icon="plus" />
          </span>
          <span>Add</span>
        </Button>
      </fieldset>
    </div>
  );
};

UIFormEDTFDate.propTypes = {
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
};

export default UIFormEDTFDate;
