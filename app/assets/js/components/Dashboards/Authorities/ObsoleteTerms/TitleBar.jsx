import { ActionHeadline, PageTitle } from "@js/components/UI/UI";

import NLogo from "@js/components/northwesternN.svg";
import React from "react";
import UIIconText from "@js/components/UI/IconText";

function DashboardsObsoleteTermsTitleBar() {
  return (
    <React.Fragment>
      <ActionHeadline data-testid="obsolete-terms-title-bar">
        <PageTitle data-testid="obsolete-terms-dashboard-title">
          <UIIconText icon={<NLogo width="24px" height="24px" />}>
            Obsolete Controlled Terms Dashboard
          </UIIconText>
        </PageTitle>
      </ActionHeadline>
    </React.Fragment>
  );
}

export default DashboardsObsoleteTermsTitleBar;