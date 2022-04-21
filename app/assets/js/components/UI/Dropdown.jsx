import React from "react";
import PropTypes from "prop-types";
import { IconArrowDown } from "@js/components/Icon";
import classNames from "classnames";

function UIDropdown({
  id = "ui-dropdown",
  isRight,
  label = "Actions",
  children,
  ...restProps
}) {
  const [isActive, setIsActive] = React.useState();

  return (
    <div
      className={classNames(["dropdown"], {
        "is-active": isActive,
        "is-right": isRight,
      })}
      {...restProps}
    >
      <div className="dropdown-trigger" data-testid="dropdown-trigger">
        <button
          onClick={() => setIsActive(!isActive)}
          className="button"
          aria-haspopup="true"
          aria-controls={id}
          data-testid="dropdown-trigger-button"
        >
          <span>{label}</span>
          <span className="icon is-small">
            <IconArrowDown aria-hidden="true" />
          </span>
        </button>
      </div>
      <div
        className="dropdown-menu"
        id={id}
        data-testid="dropdown-menu"
        role="menu"
      >
        <div className="dropdown-content" data-testid="dropdown-content">
          {children}
        </div>
      </div>
    </div>
  );
}

UIDropdown.propTypes = {
  id: PropTypes.string,
  isRight: PropTypes.bool,
  label: PropTypes.string,
  children: PropTypes.node,
};

export default UIDropdown;
