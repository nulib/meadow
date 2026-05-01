import React from "react";
import PropTypes from "prop-types";
import { IconCheckAlt } from "@js/components/Icon";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const UICheckbox = ({
  checked,
  onChange,
  label,
  disabled,
  className,
  ...props
}) => {
  const button = css`
    svg {
      color: ${checked ? "#fff !important" : "transparent"};
    }

    &:hover:not(:disabled),
    &:focus:not(:disabled) {
      svg {
        color: var(--colors-richBlack10);
      }
    }

    &:disabled {
      cursor: not-allowed;
      opacity: 0.5;
    }
  `;

  const buttonClasses = `button is-small ${checked ? "is-primary" : ""} mr-2`;

  const handleClick = (e) => {
    if (!disabled) {
      onChange(!checked);
    }
  };

  return (
    <label
      className={`checkbox is-flex is-align-items-center ${className || ""}`}
    >
      <button
        type="button"
        aria-checked={checked}
        className={buttonClasses}
        css={button}
        disabled={disabled}
        onClick={handleClick}
        role="checkbox"
        style={{
          paddingLeft: "0.5rem",
          paddingRight: "0.5rem",
        }}
        {...props}
      >
        <IconCheckAlt size="15px" />
      </button>
      {label && <span>{label}</span>}
    </label>
  );
};

UICheckbox.propTypes = {
  checked: PropTypes.bool,
  onChange: PropTypes.func.isRequired,
  label: PropTypes.string,
  disabled: PropTypes.bool,
  className: PropTypes.string,
};

UICheckbox.defaultProps = {
  checked: false,
  disabled: false,
};

export default UICheckbox;
