import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

function UISearchBarRow({ isCentered, children }) {
  return (
    <div
      className={`columns ${isCentered ? "is-centered" : ""}`}
      data-testid="search-bar-row"
    >
      <div className="column is-half-desktop">
        <UIFormField childClass="has-icons-left">
          {children}
          <span className="icon is-small is-left" data-testid="icon-search">
            <FontAwesomeIcon icon="search" />
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
