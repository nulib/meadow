import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";

function UIDropdownItem({ as = "a", isActive, children, ...restProps }) {
  const Tag = as;
  const aProps = {
    href: "#",
  };
  return (
    <Tag
      {...(as === "a" && { ...aProps })}
      className={classNames(["dropdown-item"], {
        "is-active": isActive,
      })}
      {...restProps}
    >
      {children}
    </Tag>
  );
}

UIDropdownItem.propTypes = {
  isActive: PropTypes.bool,
  children: PropTypes.node,
};

export default UIDropdownItem;
