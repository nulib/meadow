import React from "react";
import PropTypes from "prop-types";
import { CREATE_NUL_AUTHORITY_RECORD } from "@js/components/Dashboards/dashboards.gql";
import { useMutation } from "@apollo/client";
import { Button } from "@nulib/admin-react-components";
import DashboardsLocalAuthoritiesModalAdd from "@js/components/Dashboards/LocalAuthorities/ModalAdd";
import { toastWrapper } from "@js/services/helpers";

function DashboardsLocalAuthoritiesTitleBar(props) {
  const [isAddModalOpen, setIsAddModalOpen] = React.useState();
  const [createNulAuthorityRecord, { data, error, loading }] = useMutation(
    CREATE_NUL_AUTHORITY_RECORD,
    {
      onCompleted({ createNulAuthorityRecord }) {
        console.log("createNulAuthorityRecord", createNulAuthorityRecord);
        toastWrapper(
          "is-success",
          `NUL Authority Record ${createNulAuthorityRecord.label} created.`
        );
      },
    }
  );

  if (error) {
    console.error("error", error);
    return <p className="notification is-danger">{error.toString()}</p>;
  }

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
          NUL Local Authorities Dashboard
        </h1>
        <Button
          isPrimary
          onClick={() => setIsAddModalOpen(true)}
          data-testid="add-button"
        >
          Add NUL Local Authority
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

DashboardsLocalAuthoritiesTitleBar.propTypes = {};

export default DashboardsLocalAuthoritiesTitleBar;
