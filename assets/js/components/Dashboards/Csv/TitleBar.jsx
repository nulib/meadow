import React from "react";
import DashboardsCsvImport from "./Import";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { GrDocumentCsv } from "react-icons/gr";
import IconText from "@js/components/UI/IconText";
import { ActionHeadline, PageTitle } from "@js/components/UI/UI";

function DashboardsCsvTitleBar() {
  return (
    <React.Fragment>
      <ActionHeadline data-testid="csv-job-title-bar">
        <PageTitle data-testid="csv-dashboard-title">
          <IconText icon={<GrDocumentCsv />}>CSV Metadata Update</IconText>
        </PageTitle>
        <div>
          <AuthDisplayAuthorized level="MANAGER">
            <DashboardsCsvImport />
          </AuthDisplayAuthorized>
        </div>
      </ActionHeadline>
    </React.Fragment>
  );
}

DashboardsCsvTitleBar.propTypes = {};

export default DashboardsCsvTitleBar;
