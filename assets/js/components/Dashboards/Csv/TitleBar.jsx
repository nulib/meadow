import React from "react";
import DashboardsCsvImport from "./Import";

function DashboardsCsvTitleBar(props) {
  return (
    <React.Fragment>
      <div
        className="is-flex is-justify-content-space-between"
        data-testid="csv-job-title-bar"
      >
        <h1 className="title" data-testid="csv-dashboard-title">
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
