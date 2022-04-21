import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import classNames from "classnames";
import { IconSearch } from "@js/components/Icon";

function UISearchBarRow({ isCentered, children }) {
  return (
    <div
      className={classNames(["columns", "mb-5"], {
        "is-centered": isCentered,
      })}
      data-testid="search-bar-row"
    >
      <div className="column is-half-desktop">
        <UIFormField childClass="has-icons-left">
          {children}
          <span className="icon is-small is-left" data-testid="icon-search">
            <IconSearch />
          </span>
        </UIFormField>
      </div>
    </div>
  );
}

UISearchBarRow.propTypes = {
  children: PropTypes.node,
  isCentered: PropTypes.bool,
};

export default UISearchBarRow;
