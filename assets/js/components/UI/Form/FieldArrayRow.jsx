import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";

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
  isTextarea,
}) {
  const { errors, register } = useFormContext();

  return (
    <li className="field" data-testid="field-array-row">
      <div className="is-flex">
        {isTextarea ? (
          <textarea
            name={`${[name]}[${index}].metadataItem`}
            css={textareaWidth}
            rows={2}
            cols={3}
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
            placeholder={`New ${label || name}`}
            ref={register({ required: true })}
            data-testid="input-field-array"
          />
        )}
        <Button
          isText
          onClick={() => handleRemoveClick(index)}
          data-testid="button-delete-field-array-row"
        >
          <FontAwesomeIcon icon="trash" />
        </Button>
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
  isTextarea: PropTypes.bool,
};

export default FieldArrayRow;
