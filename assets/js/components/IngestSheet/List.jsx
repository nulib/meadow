import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useApolloClient, useMutation } from "@apollo/react-hooks";
import { GET_INGEST_SHEETS, DELETE_INGEST_SHEET } from "./ingestSheet.query";
import UIModalDelete from "../UI/Modal/Delete";
import { toastWrapper } from "../../services/helpers";
import UINotification from "../UI/Notification";
import { getClassFromIngestSheetStatus } from "../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { formatDate, TEMP_USER_FRIENDLY_STATUS } from "../../services/helpers";

const IngestSheetList = ({ project, subscribeToIngestSheetStatusChanges }) => {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeModal, setActiveModal] = useState();

  useEffect(() => {
    subscribeToIngestSheetStatusChanges();
  }, []);

  const client = useApolloClient();
  const [
    deleteIngestSheet,
    { data: deleteIngestSheetData, error: deleteIngestSheetError }
  ] = useMutation(DELETE_INGEST_SHEET, {
    onCompleted({ deleteIngestSheet }) {
      toastWrapper("is-success", "Ingest sheet deleted successfully");
    }
  });

  if (deleteIngestSheetError) {
    toastWrapper("is-danger", `Error: ${deleteIngestSheetError.message}`);
  }

  const handleDeleteClick = () => {
    deleteIngestSheet({ variables: { sheetId: activeModal.id } });
    onCloseModal();
  };

  const onOpenModal = (e, ingestSheet) => {
    setActiveModal(ingestSheet);
    setModalOpen(true);
  };

  const onCloseModal = () => {
    setActiveModal();
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
                        onClick={e => onOpenModal(e, { id, name })}
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
            thingToDeleteLabel={`Ingest Sheet ${
              activeModal ? activeModal.name : ""
            }`}
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
