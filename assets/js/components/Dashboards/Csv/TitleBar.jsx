import React from "react";
import PropTypes from "prop-types";
import DashboardsCsvImport from "./Import";

function DashboardsCsvTitleBar(props) {
  return (
    <React.Fragment>
      <div
        className="is-flex is-justify-content-space-between"
        data-testid="nul-authorities-title-bar"
      >
        <h1 className="title" data-testid="local-authorities-dashboard-title">
          CSV Dashboard
        </h1>
        <div>
          <DashboardsCsvImport />
        </div>
      </div>
    </React.Fragment>
  );
}

DashboardsCsvTitleBar.propTypes = {};

export default DashboardsCsvTitleBar;
