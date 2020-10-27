import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const textareaWidth = css`
  min-width: 80%;
`;

function FieldArrayRow({
  handleRemoveClick,
  index,
  item,
  label,
  name,
  itemType,
}) {
  const { errors, register } = useFormContext();

  return (
    <li className="field" data-testid="field-array-row">
      <div className="is-flex">
        {itemType == "textarea" ? (
          <textarea
            name={`${[name]}[${index}].metadataItem`}
            css={textareaWidth}
            className={`textarea ${
              errors[name] && errors[name][index] ? "is-danger" : ""
            }`}
            defaultValue={item.metadataItem}
            ref={register({ required: true })}
            data-testid="input-field-array"
          />
        ) : (
          <input
            name={`${[name]}[${index}].metadataItem`}
            className={`input ${
              errors[name] && errors[name][index] ? "is-danger" : ""
            }`}
            defaultValue={item.metadataItem}
            ref={register({ required: true })}
            data-testid="input-field-array"
          />
        )}
        <button
          type="button"
          className="button ml-1"
          onClick={() => handleRemoveClick(index)}
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
    </li>
  );
}

FieldArrayRow.propTypes = {
  handleRemoveClick: PropTypes.func,
  index: PropTypes.number,
  item: PropTypes.object,
  label: PropTypes.string,
  name: PropTypes.string,
  itemType: PropTypes.string,
};

export default FieldArrayRow;
