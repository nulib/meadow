import React from "react";
import { useApolloClient, useMutation, useQuery } from "@apollo/client";
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
import UISearchBarRow from "@js/components/UI/SearchBarRow";
import UIFormInput from "@js/components/UI/Form/Input";

const colHeaders = ["Label", "Hint"];

export default function DashboardsLocalAuthoritiesList() {
  const client = useApolloClient();
  const [currentAuthority, setCurrentAuthority] = React.useState();
  const [filteredAuthorities, setFilteredAuthorities] = React.useState([]);
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
    update(cache, { data: { deleteNulAuthorityRecord } }) {
      try {
        const { nulAuthorityRecords } = client.readQuery({
          query: GET_NUL_AUTHORITY_RECORDS,
        });
        const newData = {
          nulAuthorityRecords: nulAuthorityRecords.filter(
            (record) => record.id !== deleteNulAuthorityRecord.id
          ),
        };
        client.writeQuery({
          query: GET_NUL_AUTHORITY_RECORDS,
          data: newData,
        });
        toastWrapper(
          "is-success",
          `${deleteNulAuthorityRecord.label} deleted successfully`
        );
      } catch (e) {
        console.error(e);
        toastWrapper("is-danger", `Error deleting NUL local authority: ${e}`);
      }
    },
  });

  const [
    updateNulAuthorityRecord,
    { error: updateError, loading: updateLoading },
  ] = useMutation(UPDATE_NUL_AUTHORITY_RECORD, {
    onCompleted({ updateNulAuthorityRecord }) {
      toastWrapper(
        "is-success",
        `NUL Authority: ${updateNulAuthorityRecord.label} updated`
      );
      setCurrentAuthority(null);
    },
  });

  React.useEffect(() => {
    if (!data) {
      return;
    }
    setFilteredAuthorities(
      data.nulAuthorityRecords && data.nulAuthorityRecords.length > 0
        ? data.nulAuthorityRecords
        : []
    );
  }, [data]);

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

  const handleFilterChange = (e) => {
    const filterValue = e.target.value.toUpperCase();
    if (!filterValue) {
      return setFilteredAuthorities(data.nulAuthorityRecords);
    }
    const filteredList = filteredAuthorities.filter((item) => {
      return item.label.toUpperCase().indexOf(filterValue) > -1;
    });
    setFilteredAuthorities(filteredList);
  };

  const handleUpdateButtonClick = (record) => {
    setCurrentAuthority({ ...record });
    setModalsState({
      ...modalsState,
      update: { isOpen: true },
    });
  };

  const handleUpdate = (formData) => {
    updateNulAuthorityRecord({
      variables: {
        ...formData,
        id: currentAuthority.id,
      },
    });
  };

  return (
    <React.Fragment>
      <UISearchBarRow isCentered>
        <UIFormInput
          placeholder="Search"
          name="localAuthoritiesSearch"
          label="Filter NUL local authorities"
          onChange={handleFilterChange}
          data-testid="input-local-authorities-filter"
        />
      </UISearchBarRow>
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
          {filteredAuthorities.map((record) => {
            const { id, hint = "", label = "" } = record;

            return (
              <tr key={id} data-testid="nul-authorities-row">
                <td>{label}</td>
                <td>{hint}</td>
                <td>{id}</td>

                <td className="has-text-right is-right mb-0">
                  <div className="field is-grouped">
                    <Button
                      isLight
                      data-testid="edit-button"
                      title="Edit NUL Local Authority"
                      className="is-small"
                      onClick={() => handleUpdateButtonClick(record)}
                    >
                      <FontAwesomeIcon icon="pen" />
                    </Button>
                    <Button
                      isLight
                      data-testid="delete-button"
                      className="is-small"
                      onClick={() => handleDeleteClick(record)}
                    >
                      <FontAwesomeIcon icon="trash" />
                    </Button>
                  </div>
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
