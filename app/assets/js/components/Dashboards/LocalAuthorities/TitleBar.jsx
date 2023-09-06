import { ActionHeadline, PageTitle } from "@js/components/UI/UI";

import { Button } from "@nulib/design-system";
import { CREATE_NUL_AUTHORITY_RECORD } from "@js/components/Dashboards/dashboards.gql";
import DashboardsLocalAuthoritiesModalAdd from "@js/components/Dashboards/LocalAuthorities/ModalAdd";
import FormDownloadWrapper from "@js/components/UI/Form/DownloadWrapper";
import { IconAdd } from "@js/components/Icon";
import { IconCsv } from "@js/components/Icon";
import NLogo from "@js/components/northwesternN.svg";
import React from "react";
import UIIconText from "@js/components/UI/IconText";
import { toastWrapper } from "@js/services/helpers";
import { useMutation } from "@apollo/client";

function DashboardsLocalAuthoritiesTitleBar() {
  const [isAddModalOpen, setIsAddModalOpen] = React.useState();
  const [createNulAuthorityRecord, { _data, _error, _loading }] = useMutation(
    CREATE_NUL_AUTHORITY_RECORD,
    {
      onCompleted({ createNulAuthorityRecord }) {
        toastWrapper(
          "is-success",
          `NUL Authority Record ${createNulAuthorityRecord.label} created.`
        );
      },
      // KEEP THIS: as we can listen for a more customized message in the future when the feature is built out
      onError({ graphQLErrors, _networkError }) {
        let errorStrings = [];
        if (graphQLErrors.length > 0) {
          errorStrings = graphQLErrors.map(
            ({ message, details }) =>
              `${message}: ${details && details.label ? details.label : ""}`
          );
        }
        toastWrapper("is-danger", errorStrings.join(" \n "));
      },
    }
  );

  const handleAddLocalAuthority = (formData) => {
    createNulAuthorityRecord({
      variables: { ...formData },
    });
  };

  return (
    <React.Fragment>
      <ActionHeadline data-testid="nul-authorities-title-bar">
        <PageTitle data-testid="local-authorities-dashboard-title">
          <UIIconText icon={<NLogo width="24px" height="24px" />}>
            Local Authorities Dashboard
          </UIIconText>
        </PageTitle>

        <div className="field is-grouped">
          <p className="control">
            <Button
              isPrimary
              onClick={() => setIsAddModalOpen(true)}
              data-testid="add-button"
            >
              <IconAdd />
              <span>Add Local Authority</span>
            </Button>
          </p>
          <span className="control">
            <FormDownloadWrapper formAction="/api/authority_records/nul_authority_records.csv">
              <Button data-testid="button-csv-authority-export" type="submit">
                <IconCsv />
                <span>Export All</span>
              </Button>
            </FormDownloadWrapper>
          </span>
        </div>
      </ActionHeadline>

      <DashboardsLocalAuthoritiesModalAdd
        isOpen={isAddModalOpen}
        handleAddLocalAuthority={handleAddLocalAuthority}
        handleClose={() => setIsAddModalOpen(false)}
      />
    </React.Fragment>
  );
}

export default DashboardsLocalAuthoritiesTitleBar;
