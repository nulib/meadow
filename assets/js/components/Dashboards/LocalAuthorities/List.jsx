import React from "react";
import { useMutation, useQuery } from "@apollo/client";
import {
  DELETE_NUL_AUTHORITY_RECORD,
  GET_NUL_AUTHORITY_RECORDS,
  UPDATE_NUL_AUTHORITY_RECORD,
} from "@js/components/Dashboards/dashboards.gql";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import { toastWrapper } from "@js/services/helpers";
import DashboardsLocalAuthoritiesModalEdit from "@js/components/Dashboards/LocalAuthorities/ModalEdit";

const colHeaders = ["Label", "Hint"];

export default function DashboardsLocalAuthoritiesList() {
  const [currentAuthority, setCurrentAuthority] = React.useState();
  const [modalsState, setModalsState] = React.useState({
    delete: {
      isOpen: false,
    },
    update: {
      isOpen: false,
    },
  });

  // GraphQL
  const { loading, error, data } = useQuery(GET_NUL_AUTHORITY_RECORDS, {
    pollInterval: 1000,
  });

  const [
    deleteNulAuthorityRecord,
    { error: deleteAuthorityError, loading: deleteAuthorityLoading },
  ] = useMutation(DELETE_NUL_AUTHORITY_RECORD, {
    onCompleted({ deleteNulAuthorityRecord }) {
      toastWrapper(
        "is-success",
        `${deleteNulAuthorityRecord.label} deleted successfully`
      );
    },
  });

  const [
    updateNulAuthorityRecord,
    { error: updateError, loading: updateLoading },
  ] = useMutation(UPDATE_NUL_AUTHORITY_RECORD, {
    onCompleted({ updateNulAuthorityRecord }) {
      console.log("updateNulAuthorityRecord", updateNulAuthorityRecord);
      toastWrapper(
        "is-success",
        `NUL Authority: ${updateNulAuthorityRecord.label} updated`
      );
      setCurrentAuthority(null);
    },
  });

  if (loading || deleteAuthorityLoading || updateLoading) return null;
  if (error)
    return <p className="notification is-danger">{error.toString()}</p>;
  if (deleteAuthorityError)
    return (
      <p className="notification is-danger">
        {deleteAuthorityError.toString()}
      </p>
    );
  if (updateError)
    return <p className="notification is-danger">{updateError.toString()}</p>;

  const handleConfirmDelete = () => {
    deleteNulAuthorityRecord({ variables: { id: currentAuthority.id } });
    setCurrentAuthority(null);
    setModalsState({ ...modalsState, delete: { isOpen: false } });
  };

  const handleDeleteClick = (record) => {
    setCurrentAuthority({ ...record });
    setModalsState({
      ...modalsState,
      delete: { isOpen: true },
    });
  };

  const handleUpdateButtonClick = (record) => {
    setCurrentAuthority({ ...record });
    setModalsState({
      ...modalsState,
      update: { isOpen: true },
    });
  };

  const handleUpdate = (formData) => {
    console.log("handle update", formData, currentAuthority);
    updateNulAuthorityRecord({
      variables: {
        ...formData,
        id: currentAuthority.id,
      },
    });
  };

  return (
    <React.Fragment>
      <table
        className="table is-striped is-fullwidth"
        data-testid="local-authorities-dashboard-table"
      >
        <thead>
          <tr>
            {colHeaders.map((col) => (
              <th key={col}>{col}</th>
            ))}
            <th>Id</th>
            <th></th>
          </tr>
        </thead>
        <tbody data-testid="local-authorities-table-body">
          {data.nulAuthorityRecords.map((record) => {
            const { id, hint = "", label = "" } = record;

            return (
              <tr key={id} data-testid="nul-authorities-row">
                <td>{label}</td>
                <td>{hint}</td>
                <td>{id}</td>

                <td className="has-text-right buttons is-right mb-0">
                  <Button
                    data-testid="edit-button"
                    title="Edit NUL Local Authority"
                    onClick={() => handleUpdateButtonClick(record)}
                  >
                    <FontAwesomeIcon icon="pen" />
                  </Button>
                  <Button
                    data-testid="delete-button"
                    onClick={() => handleDeleteClick(record)}
                  >
                    <FontAwesomeIcon icon="trash" />
                  </Button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>

      <UIModalDelete
        isOpen={modalsState.delete.isOpen}
        handleClose={() =>
          setModalsState({
            ...modalsState,
            delete: {
              isOpen: false,
            },
          })
        }
        handleConfirm={handleConfirmDelete}
        thingToDeleteLabel={currentAuthority ? currentAuthority.label : ""}
      />

      <DashboardsLocalAuthoritiesModalEdit
        currentAuthority={currentAuthority}
        isOpen={modalsState.update.isOpen}
        handleClose={() =>
          setModalsState({
            ...modalsState,
            update: {
              isOpen: false,
            },
          })
        }
        handleUpdate={handleUpdate}
      />
    </React.Fragment>
  );
}
