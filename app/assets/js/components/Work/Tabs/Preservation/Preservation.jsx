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
import { Button, Icon, Notification, Popover } from "@nulib/design-system";
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
  IconCopyToClipboard,
  IconDelete,
  IconTrashCan,
  IconView,
} from "@js/components/Icon";
import * as Dialog from "@radix-ui/react-dialog";
import { styled } from "@stitches/react";

const WorkTabsPreservation = ({ work }) => {
  if (!work) return null;

  const history = useHistory();
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
      history.push(`/search`);
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

  return (
    <div data-testid="preservation-tab">
      <UITabsStickyHeader title="Preservation and Access">
        <div className="buttons is-right">
          <AuthDisplayAuthorized>
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
          </AuthDisplayAuthorized>
        </div>
      </UITabsStickyHeader>
      <div className="box mt-4">
        <div className="">
          <table
            className="table is-fullwidth is-striped is-hoverable is-narrow"
            data-testid="preservation-table"
          >
            <thead>
              <tr>
                <th>ID</th>
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
                      <td>{fileset.id}</td>
                      <td>{fileset.role?.id}</td>
                      <td>{fileset.accessionNumber}</td>
                      <td>{metadata ? metadata.originalFilename : " "}</td>
                      <td>{formatDate(fileset.insertedAt)}</td>
                      <td className="has-text-centered">
                        <Verified id={fileset.id} />
                      </td>
                      <td className="has-text-right">
                        <div>
                          <Popover>
                            <Popover.Trigger>
                              <Button as="span" data-testid="fileset-actions">
                                <span style={{ marginRight: "0.5rem" }}>
                                  Actions
                                </span>
                                <IconArrowDown aria-hidden="true" />
                              </Button>
                            </Popover.Trigger>
                            <Popover.Content
                              css={{
                                display: "flex",
                                flexDirection: "column",
                                maxWidth: "unset",
                              }}
                            >
                              <Button
                                isLowercase
                                isText
                                css={{
                                  marginBottom: "1rem",
                                  padding: "0",
                                  justifyContent: "left",
                                }}
                                onClick={() => clipboard.copy(fileset.id)}
                              >
                                <IconCopyToClipboard />
                                <span style={{ marginLeft: "0.5rem" }}>
                                  Copy id to clipboard
                                </span>
                              </Button>
                              <Button
                                isLowercase
                                isText
                                css={{
                                  marginBottom: "1rem",
                                  padding: "0",
                                  justifyContent: "left",
                                }}
                                onClick={() => {
                                  let digests = {
                                    ...fileset.coreMetadata.digests,
                                  };
                                  delete digests["__typename"];
                                  return clipboard.copy(
                                    JSON.stringify(digests)
                                  );
                                }}
                              >
                                <IconBinaryFile />
                                <span style={{ marginLeft: "0.5rem" }}>
                                  Copy checksums to clipboard
                                </span>
                              </Button>
                              <Button
                                isLowercase
                                isText
                                css={{
                                  marginBottom: "1rem",
                                  padding: "0",
                                  justifyContent: "left",
                                }}
                                onClick={() =>
                                  clipboard.copy(fileset.coreMetadata.location)
                                }
                              >
                                <IconBucket />
                                <span style={{ marginLeft: "0.5rem" }}>
                                  Copy preservation location to clipboard
                                </span>
                              </Button>

                              <Dialog.Root>
                                <DialogTrigger>
                                  <Button
                                    as="span"
                                    isLowercase
                                    isText
                                    css={{
                                      marginBottom: "1rem",
                                      padding: "0",
                                      justifyContent: "left",
                                    }}
                                    onClick={() =>
                                      handleTechnicalMetaClick(fileset)
                                    }
                                  >
                                    <IconView />
                                    <span
                                      style={{
                                        marginLeft: "0.5rem",
                                      }}
                                    >
                                      View technical metadata
                                    </span>
                                  </Button>
                                </DialogTrigger>
                                <DialogOverlay />
                                <DialogContent>
                                  <DialogClose>
                                    <Icon isSmall aria-label="Close">
                                      <Icon.Close />
                                    </Icon>
                                  </DialogClose>
                                  <DialogTitle>Technical Metadata</DialogTitle>
                                  <WorkTabsPreservationTechnical
                                    fileSet={technicalMetadata.fileSet}
                                    isVisible={true}
                                  />
                                </DialogContent>
                              </Dialog.Root>

                              <AuthDisplayAuthorized>
                                <Dialog.Root>
                                  <DialogTrigger>
                                    <Button
                                      as="span"
                                      isLowercase
                                      isText
                                      css={{
                                        padding: "0",
                                        justifyContent: "left",
                                      }}
                                      onClick={() =>
                                        handleDeleteFilesetClick(fileset)
                                      }
                                    >
                                      <IconTrashCan />
                                      <span style={{ marginLeft: "0.5rem" }}>
                                        Delete fileset
                                      </span>
                                    </Button>
                                  </DialogTrigger>
                                  <DialogOverlay />
                                  <DialogContent>
                                    <DialogClose>
                                      <Icon isSmall aria-label="Close">
                                        <Icon.Close />
                                      </Icon>
                                    </DialogClose>
                                    <DialogTitle>
                                      Delete
                                      {`Fileset: ${
                                        deleteFilesetModal.fileset.coreMetadata
                                          ? deleteFilesetModal.fileset
                                              .coreMetadata.label
                                          : ""
                                      }`}
                                    </DialogTitle>
                                    {work && (
                                      <div
                                        style={{ marginTop: "0.5rem" }}
                                        data-testid="delete-fileset-modal"
                                      >
                                        <p className="text-gray-600">
                                          This action cannot be undone.
                                        </p>
                                        <div className="buttons is-right">
                                          <Dialog.Close className="button is-text">
                                            Cancel
                                          </Dialog.Close>
                                          <button
                                            className="button is-danger"
                                            onClick={handleConfirmDeleteFileset}
                                          >
                                            Delete
                                          </button>
                                        </div>
                                      </div>
                                    )}
                                  </DialogContent>
                                </Dialog.Root>
                              </AuthDisplayAuthorized>
                            </Popover.Content>
                          </Popover>
                        </div>
                      </td>
                    </tr>
                  );
                })}
            </tbody>
          </table>
        </div>
      </div>
      <div className="container buttons">
        <AuthDisplayAuthorized action="delete">
          <Dialog.Root>
            <DialogOverlay />
            <DialogTrigger>
              <Button as="span" data-testid="button-work-delete" isDanger>
                Delete this work
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogClose>
                <Icon isSmall aria-label="Close">
                  <Icon.Close />
                </Icon>
              </DialogClose>
              <DialogTitle>
                Delete
                {` Work: ${
                  work.descriptiveMetadata
                    ? work.descriptiveMetadata.title || work.accessionNumber
                    : work.accessionNumber
                }`}
              </DialogTitle>
              {work && (
                <div
                  style={{ marginTop: "0.5rem" }}
                  data-testid="delete-fileset-modal"
                >
                  <p className="text-gray-600">This action cannot be undone.</p>
                  <div className="buttons is-right">
                    <Dialog.Close className="button is-text">
                      Cancel
                    </Dialog.Close>
                    <button
                      className="button is-danger"
                      onClick={handleDeleteWorkClick}
                    >
                      Delete
                    </button>
                  </div>
                </div>
              )}
            </DialogContent>
          </Dialog.Root>
        </AuthDisplayAuthorized>
      </div>

      <WorkTabsPreservationFileSetModal
        closeModal={() => setIsAddFilesetModalVisible(false)}
        isVisible={isAddFilesetModalVisible}
        workId={work.id}
        workTypeId={work.workType?.id}
      />
    </div>
  );
};

const DialogOverlay = styled(Dialog.Overlay, {
  backgroundColor: "#000a",
  position: "fixed",
  inset: 0,
  zIndex: 10,
});

const DialogTrigger = styled(Dialog.Trigger, {
  display: "inline-flex",
  padding: "0",
  margin: "0",
  cursor: "pointer",
  border: "none",
  background: "none",
  textTransform: "unset",
});

const DialogContent = styled(Dialog.Content, {
  backgroundColor: "white",
  borderRadius: "3px",
  boxShadow: "5px 5px 13px #0002",
  position: "fixed",
  top: "50%",
  left: "50%",
  transform: "translate(-50%, -50%)",
  width: "90vw",
  maxWidth: "700px",
  maxHeight: "85vh",
  padding: "1rem",
  overflowY: "scroll",
  zIndex: 11,
});

const DialogClose = styled(Dialog.Close, {
  position: "absolute",
  background: "none",
  border: "none",
  right: "1rem",
  cursor: "pointer",
});

const DialogTitle = styled(Dialog.Title, {
  fontWeight: "700",
});

WorkTabsPreservation.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsPreservation;