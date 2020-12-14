import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";
import { useMutation, useQuery } from "@apollo/client";
import { DELETE_WORK, VERIFY_FILE_SETS } from "@js/components/Work/work.gql";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { Button } from "@nulib/admin-react-components";
import { sortFileSets, toastWrapper } from "@js/services/helpers";
import UISkeleton from "@js/components/UI/Skeleton";
import FileSetModal from "@js/components/Work/Tabs/Preservation/FileSetModal";

const WorkTabsPreservation = ({ work }) => {
  if (!work) return null;

  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

  const [orderedFileSets, setOrderedFileSets] = useState({
    order: "asc",
    fileSets: sortFileSets({ fileSets: work.fileSets }),
  });

  const [isModalHidden, setIsModalHidden] = React.useState(true);

  const {
    data: verifyFileSetsData,
    error: verifyFileSetsError,
    loading: verifyFileSetsLoading,
  } = useQuery(VERIFY_FILE_SETS, { variables: { workId: work.id } });

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

  if (verifyFileSetsError)
    return (
      <p className="notification is-danger">
        Error loading VerifyFileSets query
      </p>
    );
  if (verifyFileSetsLoading) return <UISkeleton />;

  const { verifyFileSets } = verifyFileSetsData;

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

  const handleDeleteClick = () => {
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

  const onOpenModal = () => {
    setDeleteModalOpen(true);
  };

  const onCloseModal = () => {
    setDeleteModalOpen(false);
  };

  return (
    <div data-testid="preservation-tab">
      <UITabsStickyHeader title="Preservation and Access Masters">
        <DisplayAuthorized action="edit">
          <div className="buttons is-right">
            <Button
              data-testid="button-new-file-set"
              isPrimary
              onClick={() => setIsModalHidden(!isModalHidden)}
            >
              <span className="icon">
                <FontAwesomeIcon icon="file-image" />
              </span>
              <span>Add a fileset</span>
            </Button>
          </div>
        </DisplayAuthorized>
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
              <DisplayAuthorized action="delete">
                <th className="has-text-right">Actions</th>
              </DisplayAuthorized>
            </tr>
          </thead>
          <tbody>
            {orderedFileSets.fileSets.length > 0 &&
              orderedFileSets.fileSets.map((fileset) => {
                const metadata = fileset.metadata;
                return (
                  <tr key={fileset.id} data-testid="preservation-row">
                    <td className="is-hidden">{fileset.id}</td>
                    <td>{fileset.role}</td>
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
                    <DisplayAuthorized action="delete">
                      <td>
                        <div className="buttons-end">
                          <button
                            data-testid="button-fileset-delete"
                            className="button"
                          >
                            <FontAwesomeIcon icon="trash" />
                          </button>
                        </div>
                      </td>
                    </DisplayAuthorized>
                  </tr>
                );
              })}
          </tbody>
        </table>
        <FileSetModal
          closeModal={() => setIsModalHidden(true)}
          isHidden={isModalHidden}
          workId={work.id}
        />
      </div>
      <div className="container buttons">
        <DisplayAuthorized action="delete">
          <Button
            data-testid="button-work-delete"
            isDanger
            onClick={onOpenModal}
          >
            <span className="icon">
              <FontAwesomeIcon icon="trash" />
            </span>
            <span>Delete this work</span>
          </Button>
        </DisplayAuthorized>
      </div>

      {work && (
        <UIModalDelete
          isOpen={deleteModalOpen}
          handleClose={onCloseModal}
          handleConfirm={handleDeleteClick}
          thingToDeleteLabel={`Work: ${
            work.descriptiveMetadata
              ? work.descriptiveMetadata.title || work.accessionNumber
              : work.accessionNumber
          }`}
        />
      )}
    </div>
  );
};

WorkTabsPreservation.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsPreservation;
