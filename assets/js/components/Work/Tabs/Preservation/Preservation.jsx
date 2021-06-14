import React, { useState } from "react";
import PropTypes from "prop-types";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { useMutation, useQuery } from "@apollo/client";
import {
  DELETE_FILESET,
  DELETE_WORK,
  VERIFY_FILE_SETS,
} from "@js/components/Work/work.gql";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { Button, Notification } from "@nulib/admin-react-components";
import { sortFileSets, toastWrapper } from "@js/services/helpers";
import UISkeleton from "@js/components/UI/Skeleton";
import WorkTabsPreservationFileSetModal from "@js/components/Work/Tabs/Preservation/FileSetModal";
import WorkTabsPreservationTechnical from "@js/components/Work/Tabs/Preservation/Technical";
import { formatDate } from "@js/services/helpers";
import { useClipboard } from "use-clipboard-copy";
import {
  IconAdd,
  IconArrowDown,
  IconArrowUp,
  IconBinaryFile,
  IconBucket,
  IconCheck,
  IconDelete,
  IconTrashCan,
  IconView,
} from "@js/components/Icon";
import UIDropdown from "@js/components/UI/Dropdown";
import UIDropdownItem from "@js/components/UI/DropdownItem";
import UIIconText from "@js/components/UI/IconText";

const WorkTabsPreservation = ({ work }) => {
  if (!work) return null;

  const history = useHistory();
  const [isDeleteWorkModalVisible, setIsDeleteWorkModalVisible] =
    useState(false);
  const [isAddFilesetModalVisible, setIsAddFilesetModalVisible] =
    React.useState(false);
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

  const clipboard = useClipboard({
    onSuccess() {
      toastWrapper("is-success", `Copied successfully.`);
    },
    onError() {
      toastWrapper("is-danger", "Failed to copy.");
    },
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
      <Notification isDanger>Error loading VerifyFileSets query</Notification>
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
            <span className="is-sr-only">Verified</span>
            <IconCheck className="has-text-success" />
          </React.Fragment>
        ) : (
          <IconDelete className="has-text-danger" />
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
              <span className="icon">
                <IconAdd />
              </span>
              <span>Add a fileset</span>
            </Button>
          </div>
        </AuthDisplayAuthorized>
      </UITabsStickyHeader>
      <div className="box mt-4">
        {/* TODO: Put a mobile block display here instead of table below */}
        <div className="">
          <table
            className="table is-fullwidth is-striped is-hoverable is-narrow"
            data-testid="preservation-table"
          >
            <thead>
              <tr>
                <th className="is-hidden">ID</th>
                <th>Role</th>
                <th>Accession #</th>
                <th className="is-flex">
                  {orderedFileSets.order === "asc" ? (
                    <IconArrowDown />
                  ) : (
                    <IconArrowUp />
                  )}
                  <a className="ml-2" onClick={handleOrderClick}>
                    Filename
                  </a>
                </th>
                <th>Created</th>
                <th className="has-text-centered">Verified</th>
                <th className="has-text-right"></th>
              </tr>
            </thead>
            <tbody>
              {orderedFileSets.fileSets.length > 0 &&
                orderedFileSets.fileSets.map((fileset) => {
                  const metadata = fileset.coreMetadata;
                  return (
                    <tr key={fileset.id} data-testid="preservation-row">
                      <td className="is-hidden">{fileset.id}</td>
                      <td>{fileset.role?.id}</td>
                      <td>{fileset.accessionNumber}</td>
                      <td>{metadata ? metadata.originalFilename : " "}</td>
                      <td>{formatDate(fileset.insertedAt)}</td>
                      <td className="has-text-centered">
                        <Verified id={fileset.id} />
                      </td>
                      <td className="has-text-right">
                        <div>
                          <UIDropdown isRight>
                            <UIDropdownItem
                              data-testid="button-copy-checksum"
                              onClick={() =>
                                clipboard.copy(fileset.coreMetadata.sha256)
                              }
                            >
                              <UIIconText icon={<IconBinaryFile />}>
                                Copy checksum (sha256) to clipboard
                              </UIIconText>
                            </UIDropdownItem>
                            <UIDropdownItem
                              data-testid="button-copy-preservation-location"
                              onClick={() =>
                                clipboard.copy(fileset.coreMetadata.location)
                              }
                            >
                              <UIIconText icon={<IconBucket />}>
                                Copy preservation location to clipboard
                              </UIIconText>
                            </UIDropdownItem>
                            <UIDropdownItem
                              data-testid="button-show-technical-metadata"
                              onClick={() => handleTechnicalMetaClick(fileset)}
                            >
                              <UIIconText icon={<IconView />}>
                                View technical metadata
                              </UIIconText>
                            </UIDropdownItem>
                            <AuthDisplayAuthorized>
                              <UIDropdownItem
                                data-testid="button-fileset-delete"
                                onClick={() =>
                                  handleDeleteFilesetClick(fileset)
                                }
                              >
                                <UIIconText icon={<IconTrashCan />}>
                                  Delete fileset
                                </UIIconText>
                              </UIDropdownItem>
                            </AuthDisplayAuthorized>
                          </UIDropdown>
                        </div>
                      </td>
                    </tr>
                  );
                })}
            </tbody>
          </table>
        </div>

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
              deleteFilesetModal.fileset.coreMetadata
                ? deleteFilesetModal.fileset.coreMetadata.label
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
