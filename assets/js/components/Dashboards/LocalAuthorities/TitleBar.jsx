import React from "react";
import { CREATE_NUL_AUTHORITY_RECORD } from "@js/components/Dashboards/dashboards.gql";
import { useMutation } from "@apollo/client";
import { Button } from "@nulib/design-system";
import DashboardsLocalAuthoritiesModalAdd from "@js/components/Dashboards/LocalAuthorities/ModalAdd";
import { toastWrapper } from "@js/services/helpers";
import UIIconText from "@js/components/UI/IconText";
import NLogo from "@js/components/northwesternN.svg";
import { IconAdd } from "@js/components/Icon";
import { ActionHeadline, PageTitle } from "@js/components/UI/UI";

function DashboardsLocalAuthoritiesTitleBar() {
  const [isAddModalOpen, setIsAddModalOpen] = React.useState();
  const [createNulAuthorityRecord, { data, error, loading }] = useMutation(
    CREATE_NUL_AUTHORITY_RECORD,
    {
      onCompleted({ createNulAuthorityRecord }) {
        toastWrapper(
          "is-success",
          `NUL Authority Record ${createNulAuthorityRecord.label} created.`
        );
      },
      // KEEP THIS: as we can listen for a more customized message in the future when the feature is built out
      onError({ graphQLErrors, networkError }) {
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

        <Button
          isPrimary
          onClick={() => setIsAddModalOpen(true)}
          data-testid="add-button"
        >
          <IconAdd />
          <span>Add Local Authority</span>
        </Button>
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
