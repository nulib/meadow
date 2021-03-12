import React from "react";
import DashboardsCsvImport from "./Import";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { GrDocumentCsv } from "react-icons/gr";
import IconText from "@js/components/UI/IconText";

function DashboardsCsvTitleBar() {
  return (
    <React.Fragment>
      <div
        className="is-flex is-justify-content-space-between"
        data-testid="csv-job-title-bar"
      >
        <h1 className="title" data-testid="csv-dashboard-title">
          <IconText icon={<GrDocumentCsv />}>CSV Metadata Update</IconText>
        </h1>
        <div>
          <AuthDisplayAuthorized level="MANAGER">
            <DashboardsCsvImport />
          </AuthDisplayAuthorized>
        </div>
      </div>
    </React.Fragment>
  );
}

DashboardsCsvTitleBar.propTypes = {};

export default DashboardsCsvTitleBar;
