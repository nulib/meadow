import React from "react";
import {
  useApolloClient,
  useMutation,
  useQuery,
  useLazyQuery,
} from "@apollo/client";
import {
  DELETE_NUL_AUTHORITY_RECORD,
  GET_NUL_AUTHORITY_RECORDS,
  UPDATE_NUL_AUTHORITY_RECORD,
} from "@js/components/Dashboards/dashboards.gql";
import { AUTHORITIES_SEARCH } from "@js/components/Work/controlledVocabulary.gql";
import { Button, Notification } from "@nulib/design-system";
import { Link } from "react-router-dom";
import { toastWrapper } from "@js/services/helpers";
import DashboardsLocalAuthoritiesModalEdit from "@js/components/Dashboards/LocalAuthorities/ModalEdit";
import UIFormInput from "@js/components/UI/Form/Input";
import { ModalDelete, SearchBarRow } from "@js/components/UI/UI";
import { IconEdit, IconImages, IconTrashCan } from "@js/components/Icon";

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
  const [searchValue, setSearchValue] = React.useState("");

  // GraphQL
  const { loading, error, data } = useQuery(GET_NUL_AUTHORITY_RECORDS, {
    variables: { limit: 100 },
    pollInterval: 1000,
  });

  function filterValues() {
    if (!data) return;
    if (searchValue) {
      authoritiesSearch({
        variables: {
          authority: "nul-authority",
          query: searchValue,
        },
      });
    } else {
      setFilteredAuthorities(data.nulAuthorityRecords);
    }
  }

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
        filterValues();
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
      filterValues();
    },
  });

  const [
    authoritiesSearch,
    {
      error: errorAuthoritiesSearch,
      loading: loadingAuthoritiesSearch,
      data: dataAuthoritiesSearch,
    },
  ] = useLazyQuery(AUTHORITIES_SEARCH, {
    fetchPolicy: "network-only",
    onCompleted: (data) => {
      setFilteredAuthorities(dataAuthoritiesSearch.authoritiesSearch);
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      toastWrapper(
        "is-danger",
        `Error searching NUL local authorities through GraphQL LazyQuery`
      );
    },
  });

  React.useEffect(() => {
    if (!data) return;
    filterValues();
  }, [data, searchValue]);

  if (loading || deleteAuthorityLoading || updateLoading) return null;
  if (error) return <Notification isDanger>{error.toString()}</Notification>;
  if (deleteAuthorityError)
    return (
      <Notification isDanger>{deleteAuthorityError.toString()}</Notification>
    );
  if (updateError)
    return <Notification isDanger>{updateError.toString()}</Notification>;

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
    updateNulAuthorityRecord({
      variables: {
        ...formData,
        id: currentAuthority.id,
      },
    });
  };

  const handleSearchChange = (e) => {
    setSearchValue(e.target.value);
  };

  return (
    <React.Fragment>
      <SearchBarRow isCentered>
        <UIFormInput
          placeholder="Search"
          name="nulSearch"
          label="NUL search"
          onChange={handleSearchChange}
          value={searchValue}
        />
      </SearchBarRow>

      <div className="table-container">
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
              const { id = "", hint = "", label = "" } = record;

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
                        <IconEdit />
                      </Button>
                      <Button
                        isLight
                        data-testid="delete-button"
                        className="is-small"
                        onClick={() => handleDeleteClick(record)}
                      >
                        <IconTrashCan />
                      </Button>
                      <Link
                        data-testid="button-to-search"
                        className="button is-small is-light"
                        title="View works containing this record"
                        to={{
                          pathname: "/search",
                          state: {
                            passedInSearchTerm: `all_controlled_terms:\"${id}\"`,
                          },
                        }}
                      >
                        <IconImages />
                      </Link>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <ModalDelete
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
