import React, { useState } from "react";
import UIModalDelete from "../UI/Modal/Delete";
import {
  DELETE_INGEST_SHEET,
  APPROVE_INGEST_SHEET,
  GET_INGEST_SHEETS,
} from "./ingestSheet.gql";
import { useMutation, useApolloClient } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { toastWrapper } from "../../services/helpers";
import IngestSheetDownload from "./Completed/Download";

const IngestSheetActionRow = ({ projectId, sheetId, status, name }) => {
  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const client = useApolloClient();
  const [deleteIngestSheet, { data: deleteIngestSheetData }] = useMutation(
    DELETE_INGEST_SHEET,
    {
      update(cache, { data: { deleteIngestSheet } }) {
        try {
          const { project } = client.readQuery({
            query: GET_INGEST_SHEETS,
            variables: { projectId },
          });
          const index = project.ingestSheets.findIndex(
            (ingestSheet) => ingestSheet.id === deleteIngestSheet.id
          );
          project.ingestSheets.splice(index, 1);
          client.writeQuery({
            query: GET_INGEST_SHEETS,
            data: { project },
          });
        } catch (error) {
          console.log("Error reading from cache", error);
        }
      },
      onCompleted({ deleteIngestSheet }) {
        toastWrapper("is-success", `Ingest sheet ${name} deleted successfully`);
        history.push(`/project/${projectId}`);
      },
    }
  );
  const [
    approveIngestSheet,
    { loading: approveLoading, error: approveError },
  ] = useMutation(APPROVE_INGEST_SHEET);

  const handleApproveClick = () => {
    approveIngestSheet({ variables: { id: sheetId } });
  };

  const handleDeleteClick = () => {
    deleteIngestSheet({ variables: { sheetId: sheetId } });
  };

  const onOpenModal = () => {
    setDeleteModalOpen(true);
  };

  const onCloseModal = () => {
    setDeleteModalOpen(false);
  };

  return (
    <>
      <div className="buttons is-right">
        {status === "VALID" && (
          <button className="button is-primary" onClick={handleApproveClick}>
            <span className="icon">
              <FontAwesomeIcon icon="thumbs-up" />
            </span>{" "}
            <span>Approve ingest sheet</span>
          </button>
        )}

        {status === "COMPLETED" && <IngestSheetDownload sheetId={sheetId} />}

        {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) >
          -1 && (
          <button className={`button`} onClick={onOpenModal}>
            <span className="icon">
              <FontAwesomeIcon icon="trash" />
            </span>{" "}
            <span>Delete and start over</span>
          </button>
        )}
      </div>

      {approveLoading && <p>Approval loading...</p>}
      {approveError && <p>Error : (please try again)</p>}

      <UIModalDelete
        isOpen={deleteModalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Ingest Sheet ${name}`}
      />
    </>
  );
};

IngestSheetActionRow.propTypes = {
  projectId: PropTypes.string,
  sheetId: PropTypes.string,
  status: PropTypes.string,
  name: PropTypes.string,
};

export default IngestSheetActionRow;
