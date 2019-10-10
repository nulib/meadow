import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useApolloClient, useMutation } from "@apollo/react-hooks";
import { GET_INGEST_SHEETS, DELETE_INGEST_SHEET } from "./ingestSheet.query";
import UIModalDelete from "../UI/Modal/Delete";
import TrashIcon from "../../../css/fonts/zondicons/trash.svg";
import { useToasts } from "react-toast-notifications";

// delete/refine later
export const TEMP_USER_FRIENDLY_STATUS = {
  UPLOADED: "Validation in progress...",
  ROW_FAIL: "Validation Errors",
  FILE_FAIL: "Validation Errors",
  VALID: "Valid, waiting for approval",
  APPROVED: "Ingest in progress...",
  COMPLETED: "Ingest Complete"
};

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
    update(
      cache,
      {
        data: { deleteIngestSheet }
      }
    ) {
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
    }
  });

  if (deleteIngestSheetError) {
    addToast(`Error: ${deleteIngestSheetError.message}`, {
      appearance: "error",
      autoDismiss: true
    });
  }

  const handleDeleteClick = () => {
    deleteIngestSheet({ variables: { ingestSheetId: activeModal } });
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
        <p data-testid="no-ingest-sheets-notification">
          No ingest sheets are found.
        </p>
      )}

      {project.ingestSheets.length > 0 && (
        <>
          <table>
            <caption>All Project Ingest Sheets</caption>
            <thead>
              <tr>
                <th>Ingest sheet title</th>
                <th>Last updated</th>
                <th>Status</th>
                <th></th>
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
                  <td>{updatedAt}</td>
                  <td>{TEMP_USER_FRIENDLY_STATUS[status]}</td>
                  <td className="text-right">
                    <button onClick={e => onOpenModal(e, id)}>
                      <TrashIcon className="icon cursor-pointer" />
                    </button>
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
