import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UITagNotYetSupported from "@js/components/UI/TagNotYetSupported";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";
import { useMutation } from "@apollo/client";
import { DELETE_WORK } from "@js/components/Work/work.gql";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { Button } from "@nulib/admin-react-components";
import { toastWrapper } from "@js/services/helpers";

const WorkTabsPreservation = ({ work }) => {
  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
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

  const handleDeleteClick = () => {
    deleteWork({ variables: { workId: work.id } });
  };
  const onOpenModal = () => {
    setDeleteModalOpen(true);
  };

  const onCloseModal = () => {
    setDeleteModalOpen(false);
  };

  return (
    <>
      <UITabsStickyHeader title="Preservation and Access Masters" />
      <div className="box mt-4">
        <table className="table is-fullwidth is-striped is-hoverable is-fixed">
          <thead>
            <tr>
              <th>Role</th>
              <th>Filename</th>
              <th>Checksum</th>
              <th>s3 Key</th>
              <th>Verified</th>
              <DisplayAuthorized action="delete">
                <th className="has-text-right">Actions</th>{" "}
              </DisplayAuthorized>
            </tr>
          </thead>
          <tbody>
            {work.fileSets &&
              work.fileSets.map((fileset) => {
                const metadata = fileset.metadata;
                return (
                  <tr key={fileset.id}>
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
                    <td>
                      <UITagNotYetSupported label="Display not yet supported" />
                    </td>
                    <DisplayAuthorized action="delete">
                      <td>
                        <div className="buttons-end">
                          <button className="button">
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
      </div>
      <div className="container buttons">
        <DisplayAuthorized action="delete">
          <Button data-testid="delete-button" onClick={onOpenModal}>
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
          thingToDeleteLabel={`Work ${
            work.descriptiveMetadata
              ? work.descriptiveMetadata.title || work.accessionNumber
              : work.accessionNumber
          }`}
        />
      )}
    </>
  );
};

WorkTabsPreservation.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsPreservation;
