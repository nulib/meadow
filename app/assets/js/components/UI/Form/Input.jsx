import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";
import { Button, Icon } from "@nulib/design-system";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const clearButtonStyles = css`
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  background: none !important;
  border: none !important;
  width: 20px;
  height: 20px;
  cursor: pointer;
`;

const UIFormInput = ({
  id = "",
  isReactHookForm,
  label = "",
  name,
  required,
  type = "text",
  showClearButton = false,
  ...passedInProps
}) => {
  let errors = {},
    register,
    setValue,
    watch;

  if (isReactHookForm) {
    const context = useFormContext();
    errors = context.formState.errors;
    register = context.register;
    setValue = context.setValue;
    watch = context.watch;
  }

  const currentValue = isReactHookForm ? watch(name) : passedInProps.value;
  const shouldShowClear =
    showClearButton && currentValue && currentValue.length > 0;

  const handleClear = () => {
    if (isReactHookForm) {
      setValue(name, "");
    } else if (passedInProps.onChange) {
      // For non-react-hook-form usage
      passedInProps.onChange({ target: { name, value: "" } });
    }
  };

  return (
    <div>
      <input
        id={id || name}
        name={name}
        type={type}
        {...(register && register(name, { required }))}
        className={`input ${errors[name] ? "is-danger" : ""}`}
        {...passedInProps}
      />
      {shouldShowClear && (
        <Button
          type="button"
          onClick={handleClear}
          className="clear-button"
          css={clearButtonStyles}
          aria-label="Clear input"
        >
          <Icon isSmall isText>
            <Icon.Close />
          </Icon>
        </Button>
      )}
      {errors[name] && (
        <p data-testid="input-errors" className="help is-danger">
          {label || name} field is required
        </p>
      )}
    </div>
  );
};

UIFormInput.propTypes = {
  id: PropTypes.string,
  isReactHookForm: PropTypes.bool,
  name: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  type: PropTypes.oneOf(["date", "number", "text", "email", "hidden"]),
};

export default UIFormInput;
