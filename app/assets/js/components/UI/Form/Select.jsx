import PropTypes from "prop-types";
import React from "react";
import { useFormContext } from "react-hook-form";

/**
 * `isReadOnly` simulates readonly for <select>:
 * - Uses CSS to block interaction (keeps RHF registration + submission).
 * - Avoid `disabled` if you need the value in RHF form state.
 */
const UIFormSelect = ({
  isReactHookForm,
  name,
  label,
  hasErrors,
  required,
  options = [],
  defaultValue,
  showHelper,
  isReadOnly = false,
  ...props
}) => {
  let errors = {};
  let register;

  if (isReactHookForm) {
    const ctx = useFormContext();
    errors = ctx.formState.errors;
    register = ctx.register;
  }

  const { style: styleProp, ...restProps } = props;
  const regProps = register ? register(name, { required }) : {};

  return (
    <>
      <div className={`select ${hasErrors || errors[name] ? "is-danger" : ""}`}>
        <select
          name={name}
          {...regProps}
          data-testid="select-level"
          defaultValue={defaultValue}
          aria-readonly={isReadOnly || undefined}
          tabIndex={isReadOnly ? -1 : undefined}
          style={{
            pointerEvents: isReadOnly ? "none" : undefined,
            opacity: isReadOnly ? 0.75 : undefined,
            ...styleProp,
          }}
          {...restProps}
        >
          {showHelper && <option value="">-- Select --</option>}
          {options.map((opt) => (
            <option key={opt.id || opt.value} value={opt.id || opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      {(hasErrors || errors[name]) && (
        <p data-testid="select-errors" className="help is-danger">
          {label || name} field is required
        </p>
      )}
    </>
  );
};

UIFormSelect.propTypes = {
  isReactHookForm: PropTypes.bool,
  name: PropTypes.string.isRequired,
  label: PropTypes.string,
  hasErrors: PropTypes.bool,
  required: PropTypes.bool,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      label: PropTypes.string.isRequired,
      value: PropTypes.string,
    }),
  ),
  showHelper: PropTypes.bool,
  defaultValue: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  isReadOnly: PropTypes.bool,
};

export default UIFormSelect;
