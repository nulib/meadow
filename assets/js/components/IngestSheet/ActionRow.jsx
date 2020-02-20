import React, { useState } from "react";
import ButtonGroup from "../UI/ButtonGroup";
import UIModalDelete from "../UI/Modal/Delete";
import { DELETE_INGEST_SHEET, APPROVE_INGEST_SHEET } from "./ingestSheet.query";
import { useMutation } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { useToasts } from "react-toast-notifications";
import { useHistory } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const IngestSheetActionRow = ({ projectId, sheetId, status }) => {
  const history = useHistory();
  const { addToast } = useToasts();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [deleteIngestSheet, { data: deleteIngestSheetData }] = useMutation(
    DELETE_INGEST_SHEET,
    {
      onCompleted({ deleteIngestSheet }) {
        addToast("Ingest sheet deleted successfully", {
          appearance: "success",
          autoDismiss: true
        });
        history.push(`/project/${projectId}`);
      }
    }
  );
  const [
    approveIngestSheet,
    { loading: approveLoading, error: approveError }
  ] = useMutation(APPROVE_INGEST_SHEET);

  const showApproveButton = status === "VALID";

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
    <div className="box is-shadowless">
      <ButtonGroup>
        {showApproveButton && (
          <button className="button is-primary" onClick={handleApproveClick}>
            <span className="icon">
              <FontAwesomeIcon icon="thumbs-up" />
            </span>{" "}
            <span>Approve ingest sheet</span>
          </button>
        )}
        <button className={`button`} onClick={onOpenModal}>
          <span className="icon">
            <FontAwesomeIcon icon="trash" />
          </span>{" "}
          <span>Delete ingest sheet and start over</span>
        </button>
      </ButtonGroup>

      {approveLoading && <p>Approval loading...</p>}
      {approveError && <p>Error : (please try again)</p>}

      <UIModalDelete
        isOpen={deleteModalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Ingest Sheet`}
      />
    </div>
  );
};

IngestSheetActionRow.propTypes = {
  projectId: PropTypes.string,
  sheetId: PropTypes.string,
  status: PropTypes.string
};

export default IngestSheetActionRow;
