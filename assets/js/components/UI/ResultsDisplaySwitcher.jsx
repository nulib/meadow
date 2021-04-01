import React from "react";
import PropTypes from "prop-types";
import { IconCard, IconList } from "@js/components/Icon";

const UIResultsDisplaySwitcher = ({ isListView, onGridClick, onListClick }) => {
  return (
    <div className="columns">
      <div className="column pt-0">
        <button
          className={`button is-fullwidth ${
            isListView ? "is-light" : "is-text"
          }`}
          onClick={onListClick}
          title="List view"
        >
          <span className={`icon`}>
            <IconList />
          </span>
          <span>List view</span>
        </button>
      </div>
      <div className="column pt-0">
        <button
          className={`button is-fullwidth ${
            isListView ? "is-text" : "is-light"
          }`}
          onClick={onGridClick}
          title="Grid view"
        >
          <span className={`icon`}>
            <IconCard />
          </span>
          <span>Grid view</span>
        </button>
      </div>
    </div>
  );
};

UIResultsDisplaySwitcher.propTypes = {
  isListView: PropTypes.bool,
  onGridClick: PropTypes.func,
  onListClick: PropTypes.func,
};

export default UIResultsDisplaySwitcher;
