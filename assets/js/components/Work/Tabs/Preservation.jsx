import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { useMutation, useQuery } from "@apollo/client";
import {
  DELETE_FILESET,
  DELETE_WORK,
  GET_WORK,
  VERIFY_FILE_SETS,
} from "@js/components/Work/work.gql";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { Button } from "@nulib/admin-react-components";
import { sortFileSets, toastWrapper } from "@js/services/helpers";
import UISkeleton from "@js/components/UI/Skeleton";
import WorkTabsPreservationFileSetModal from "@js/components/Work/Tabs/Preservation/FileSetModal";
import WorkTabsPreservationTechnical from "@js/components/Work/Tabs/Preservation/Technical";
import IconAdd from "@js/components/Icon/Add";
import IconView from "@js/components/Icon/View";
import IconTrashCan from "@js/components/Icon/TrashCan";

const WorkTabsPreservation = ({ work }) => {
  if (!work) return null;

  const history = useHistory();
  const [isDeleteWorkModalVisible, setIsDeleteWorkModalVisible] = useState(
    false
  );
  const [
    isAddFilesetModalVisible,
    setIsAddFilesetModalVisible,
  ] = React.useState(false);
  const [orderedFileSets, setOrderedFileSets] = useState({
    order: "asc",
    fileSets: sortFileSets({ fileSets: work.fileSets }),
  });

  // These 2 state variables keep track of whether a modal is open,
  // and also additional data which the dependent modals rely upon
  const [technicalMetadata, setTechnicalMetadata] = React.useState({
    fileSet: {},
    isVisible: false,
  });
  const [deleteFilesetModal, setDeleteFilesetModal] = React.useState({
    fileset: {},
    isVisible: false,
  });

  const {
    data: verifyFileSetsData,
    error: verifyFileSetsError,
    loading: verifyFileSetsLoading,
  } = useQuery(VERIFY_FILE_SETS, { variables: { workId: work.id } });

  /**
   * Delete a Fileset
   */
  const [deleteFileSet, { data: deleteFileSetData }] = useMutation(
    DELETE_FILESET,
    {
      onError({ graphQLErrors, networkError }) {
        let errorStrings = [];
        if (graphQLErrors.length > 0) {
          errorStrings = graphQLErrors.map(
            ({ message, details }) =>
              `${message}: ${details && details.title ? details.title : ""}`
          );
          toastWrapper("is-danger", errorStrings.join(" \n "));
        }
        toastWrapper(
          "is-danger",
          "There was an unknown error deleting the Fileset"
        );
      },
      update(cache, { data: { deleteFileSet } }) {
        try {
          cache.modify({
            id: cache.identify(work),
            fields: {
              fileSets(existingfileSetsRefs, { readField }) {
                return existingfileSetsRefs.filter(
                  (fileSetRef) =>
                    deleteFileSet.id !== readField("id", fileSetRef)
                );
              },
            },
          });
        } catch (error) {
          console.error("Error reading from cache after fileset delete", error);
        }
      },
    }
  );

  /**
   * Delete a Work
   * */
  const [deleteWork, { data: deleteWorkData }] = useMutation(DELETE_WORK, {
    onCompleted({ deleteWork: { project, ingestSheet, descriptiveMetadata } }) {
      toastWrapper(
        "is-success",
        `Work ${
          descriptiveMetadata ? descriptiveMetadata.title || "" : ""
        } deleted successfully`
      );
      history.push(`/project/${project.id}/ingest-sheet/${ingestSheet.id}`);
    },
  });

  /**
   * Reorder filesets
   */
  React.useEffect(() => {
    setOrderedFileSets({
      ...orderedFileSets,
      fileSets: sortFileSets({ fileSets: work.fileSets }),
    });
  }, [work.fileSets]);

  if (verifyFileSetsError)
    return (
      <p className="notification is-danger">
        Error loading VerifyFileSets query
      </p>
    );
  if (verifyFileSetsLoading) return <UISkeleton />;

  const { verifyFileSets } = verifyFileSetsData;

  /**
   * Helper component showing verified state
   */
  const Verified = ({ id }) => {
    if (!verifyFileSets || !id) return null;
    const fileset = verifyFileSets.find((obj) => obj.fileSetId === id);

    return (
      <div data-testid="verified">
        {fileset && fileset.verified ? (
          <React.Fragment>
            <span className="sr-only">Verified</span>
            <FontAwesomeIcon icon="check" className="has-text-success" />
          </React.Fragment>
        ) : (
          <FontAwesomeIcon icon="times" className="has-text-danger" />
        )}
      </div>
    );
  };

  const handleConfirmDeleteFileset = () => {
    deleteFileSet({
      variables: { fileSetId: deleteFilesetModal.fileset.id },
    });
    setDeleteFilesetModal({ fileset: {}, isVisible: false });
  };

  const handleDeleteFilesetClick = (fileset) => {
    setDeleteFilesetModal({ fileset, isVisible: true });
  };

  const handleDeleteWorkClick = () => {
    deleteWork({ variables: { workId: work.id } });
  };

  const handleOrderClick = () => {
    const order = orderedFileSets.order === "asc" ? "desc" : "asc";
    const fileSets = sortFileSets({
      order,
      fileSets: orderedFileSets.fileSets,
    });
    setOrderedFileSets({ order, fileSets });
  };

  const handleTechnicalMetaClick = (fileSet = {}) => {
    setTechnicalMetadata({ fileSet: { ...fileSet }, isVisible: true });
  };

  const onOpenDeleteWorkModal = () => {
    setIsDeleteWorkModalVisible(true);
  };

  const onCloseDeleteWorkModal = () => {
    setIsDeleteWorkModalVisible(false);
  };

  return (
    <div data-testid="preservation-tab">
      <UITabsStickyHeader title="Preservation and Access">
        <AuthDisplayAuthorized>
          <div className="buttons is-right">
            <Button
              data-testid="button-new-file-set"
              isPrimary
              onClick={() =>
                setIsAddFilesetModalVisible(!isAddFilesetModalVisible)
              }
            >
              <IconAdd className="icon" />
              <span>Add a fileset</span>
            </Button>
          </div>
        </AuthDisplayAuthorized>
      </UITabsStickyHeader>
      <div className="box mt-4">
        <table
          className="table is-fullwidth is-striped is-hoverable is-fixed"
          data-testid="preservation-table"
        >
          <thead>
            <tr>
              <th className="is-hidden">ID</th>
              <th>Role</th>
              <th className="is-flex">
                <FontAwesomeIcon
                  icon={[
                    "fas",
                    orderedFileSets.order === "asc"
                      ? "sort-alpha-down"
                      : "sort-alpha-down-alt",
                  ]}
                  className="icon"
                />
                <a className="ml-2" onClick={handleOrderClick}>
                  Filename
                </a>
              </th>
              <th>Checksum</th>
              <th>s3 Key</th>
              <th className="has-text-centered">Verified</th>
              <AuthDisplayAuthorized action="delete">
                <th className="has-text-right">Actions</th>
              </AuthDisplayAuthorized>
            </tr>
          </thead>
          <tbody>
            {orderedFileSets.fileSets.length > 0 &&
              orderedFileSets.fileSets.map((fileset) => {
                const metadata = fileset.metadata;
                return (
                  <tr key={fileset.id} data-testid="preservation-row">
                    <td className="is-hidden">{fileset.id}</td>
                    <td>{fileset.role && fileset.role.label}</td>
                    <td className="break-word">
                      {metadata ? metadata.originalFilename : " "}
                    </td>
                    <td className="break-word">
                      {metadata ? metadata.sha256 : ""}
                    </td>
                    <td className="break-word">
                      {metadata ? metadata.location : ""}
                    </td>
                    <td className="has-text-centered">
                      <Verified id={fileset.id} />
                    </td>
                    <AuthDisplayAuthorized action="delete">
                      <td>
                        <div className="buttons buttons-end">
                          <Button
                            isLight
                            data-testid="button-show-technical-metadata"
                            onClick={() => handleTechnicalMetaClick(fileset)}
                            title="View technical metadata"
                          >
                            <IconView />
                          </Button>
                          <Button
                            isLight
                            data-testid="button-fileset-delete"
                            onClick={() => handleDeleteFilesetClick(fileset)}
                            title="Delete file set"
                          >
                            <IconTrashCan />
                          </Button>
                        </div>
                      </td>
                    </AuthDisplayAuthorized>
                  </tr>
                );
              })}
          </tbody>
        </table>
        <WorkTabsPreservationFileSetModal
          closeModal={() => setIsAddFilesetModalVisible(false)}
          isVisible={isAddFilesetModalVisible}
          workId={work.id}
        />
      </div>
      <div className="container buttons">
        <AuthDisplayAuthorized action="delete">
          <Button
            data-testid="button-work-delete"
            isDanger
            onClick={onOpenDeleteWorkModal}
          >
            Delete this work
          </Button>
        </AuthDisplayAuthorized>
      </div>

      {work && (
        <>
          <UIModalDelete
            isOpen={isDeleteWorkModalVisible}
            handleClose={onCloseDeleteWorkModal}
            handleConfirm={handleDeleteWorkClick}
            thingToDeleteLabel={`Work: ${
              work.descriptiveMetadata
                ? work.descriptiveMetadata.title || work.accessionNumber
                : work.accessionNumber
            }`}
          />
          <UIModalDelete
            isOpen={deleteFilesetModal.isVisible}
            handleClose={() =>
              setDeleteFilesetModal({ fileset: null, isVisible: false })
            }
            handleConfirm={handleConfirmDeleteFileset}
            thingToDeleteLabel={`Fileset: ${
              deleteFilesetModal.fileset.metadata
                ? deleteFilesetModal.fileset.metadata.label
                : ""
            }`}
          />
        </>
      )}

      <WorkTabsPreservationTechnical
        fileSet={technicalMetadata.fileSet}
        handleClose={() =>
          setTechnicalMetadata({ fileSet: {}, isVisible: false })
        }
        isVisible={technicalMetadata.isVisible}
      />
    </div>
  );
};

WorkTabsPreservation.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsPreservation;
