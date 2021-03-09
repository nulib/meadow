import React from "react";
import { CREATE_NUL_AUTHORITY_RECORD } from "@js/components/Dashboards/dashboards.gql";
import { useMutation } from "@apollo/client";
import { Button } from "@nulib/admin-react-components";
import DashboardsLocalAuthoritiesModalAdd from "@js/components/Dashboards/LocalAuthorities/ModalAdd";
import { toastWrapper } from "@js/services/helpers";
import UIIconText from "@js/components/UI/IconText";
import NLogo from "@js/components/northwesternN.svg";
import IconAdd from "@js/components/Icon/Add";

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
      <div
        className="is-flex is-justify-content-space-between"
        data-testid="nul-authorities-title-bar"
      >
        <h1 className="title" data-testid="local-authorities-dashboard-title">
          <UIIconText
            icon={<NLogo width="1.5rem" height="1.5rem" />}
            text="Local Authorities Dashboard"
          />
        </h1>
        <Button
          isPrimary
          onClick={() => setIsAddModalOpen(true)}
          data-testid="add-button"
        >
          <IconAdd className="icon" />
          <span>Add Local Authority</span>
        </Button>
      </div>
      <DashboardsLocalAuthoritiesModalAdd
        isOpen={isAddModalOpen}
        handleAddLocalAuthority={handleAddLocalAuthority}
        handleClose={() => setIsAddModalOpen(false)}
      />
    </React.Fragment>
  );
}

export default DashboardsLocalAuthoritiesTitleBar;
