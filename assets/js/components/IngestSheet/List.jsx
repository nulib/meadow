import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useApolloClient, useMutation } from "@apollo/react-hooks";
import { GET_INGEST_SHEETS, DELETE_INGEST_SHEET } from "./ingestSheet.query";
import UIModalDelete from "../UI/Modal/Delete";
import { useToasts } from "react-toast-notifications";
import UINotification from "../UI/Notification";
import { getClassFromIngestSheetStatus } from "../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { formatDate, TEMP_USER_FRIENDLY_STATUS } from "../../services/helpers";

const IngestSheetList = ({ project, subscribeToIngestSheetStatusChanges }) => {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeModal, setActiveModal] = useState();
  const { addToast } = useToasts();

  useEffect(() => {
    subscribeToIngestSheetStatusChanges();
  }, []);

  const client = useApolloClient();
  const [
    deleteIngestSheet,
    { data: deleteIngestSheetData, error: deleteIngestSheetError }
  ] = useMutation(DELETE_INGEST_SHEET, {
    update(cache, { data: { deleteIngestSheet } }) {
      try {
        const { project } = client.readQuery({
          query: GET_INGEST_SHEETS,
          variables: { projectId }
        });

        const index = project.ingestSheets.findIndex(
          ingestSheet => ingestSheet.id === deleteIngestSheet.id
        );

        project.ingestSheets.splice(index, 1);

        client.writeQuery({
          query: GET_INGEST_SHEETS,
          data: { project }
        });
      } catch (error) {
        console.log("Error reading from cache", error);
      }
    },
    onCompleted({ deleteIngestSheet }) {
      addToast("Ingest sheet deleted successfully", {
        appearance: "success",
        autoDismiss: true
      });
    }
  });

  if (deleteIngestSheetError) {
    addToast(`Error: ${deleteIngestSheetError.message}`, {
      appearance: "error",
      autoDismiss: true
    });
  }

  const handleDeleteClick = () => {
    deleteIngestSheet({ variables: { sheetId: activeModal } });
    onCloseModal();
  };

  const onOpenModal = (e, ingestSheet) => {
    setActiveModal(ingestSheet);
    setModalOpen(true);
  };

  const onCloseModal = () => {
    setActiveModal(null);
    setModalOpen(false);
  };

  return (
    <div>
      {project.ingestSheets.length === 0 && (
        <UINotification
          data-testid="no-ingest-sheets-notification"
          className="is-warning"
        >
          No ingest sheets are found.
        </UINotification>
      )}

      {project.ingestSheets.length > 0 && (
        <>
          <table className="table is-striped is-hoverable is-fullwidth">
            <caption>All Project Ingest Sheets</caption>
            <thead>
              <tr>
                <th>Ingest sheet title</th>
                <th className="has-text-right">Last updated</th>
                <th>Status</th>
                <th className="has-text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {project.ingestSheets.map(({ id, name, status, updatedAt }) => (
                <tr key={id}>
                  <td>
                    <Link to={`/project/${project.id}/ingest-sheet/${id}`}>
                      {name}
                    </Link>
                  </td>
                  <td className="has-text-right">{formatDate(updatedAt)}</td>
                  <td>
                    <span
                      className={`tag ${getClassFromIngestSheetStatus(status)}`}
                    >
                      {TEMP_USER_FRIENDLY_STATUS[status]}
                    </span>
                  </td>
                  <td className="has-text-right">
                    {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(
                      status
                    ) > -1 && (
                      <button
                        className="button"
                        onClick={e => onOpenModal(e, id)}
                      >
                        {<FontAwesomeIcon icon="trash" />}{" "}
                        <span className="sr-only">Delete</span>
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <UIModalDelete
            isOpen={modalOpen}
            handleClose={onCloseModal}
            handleConfirm={handleDeleteClick}
            thingToDeleteLabel={`Ingest Sheet`}
          />
        </>
      )}
    </div>
  );
};

IngestSheetList.propTypes = {
  project: PropTypes.object.isRequired,
  subscribeToIngestSheetStatusChanges: PropTypes.func.isRequired
};

export default IngestSheetList;
