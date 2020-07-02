import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const UIResultsDisplaySwitcher = ({ isListView, onGridClick, onListClick }) => {
  return (
    <div className="buttons is-right ">
      <button
        className="button is-text"
        onClick={onGridClick}
        title="Grid View"
      >
        <span className={`icon ${isListView ? "has-text-grey" : ""}`}>
          <FontAwesomeIcon size="2x" icon="th-large" />
        </span>
      </button>

      <button
        className="button is-text"
        onClick={onListClick}
        title="List View"
      >
        <span className={`icon ${!isListView ? "has-text-grey" : ""}`}>
          <FontAwesomeIcon size="2x" icon="th-list" />
        </span>
      </button>
    </div>
  );
};

UIResultsDisplaySwitcher.propTypes = {
  isListView: PropTypes.bool,
  onGridClick: PropTypes.func,
  onListClick: PropTypes.func,
};

export default UIResultsDisplaySwitcher;
