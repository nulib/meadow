import React, { useState } from "react";
import ButtonGroup from "../UI/ButtonGroup";
import UIButton from "../UI/Button";
import CheckMarkIcon from "../../../css/fonts/zondicons/checkmark.svg";
import TrashIcon from "../../../css/fonts/zondicons/trash.svg";
import UIModalDelete from "../UI/Modal/Delete";
import {
  DELETE_INGEST_SHEET,
  APPROVE_INGEST_SHEET
} from "./ingestSheet.query";
import { useMutation } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import ReactRouterPropTypes from "react-router-prop-types";
import { withRouter } from "react-router-dom";
import { useToasts } from "react-toast-notifications";

const IngestSheetActionRow = ({
  projectId,
  sheetId,
  status,
  history
}) => {
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
    <div className="my-12">
      <ButtonGroup>
        {showApproveButton && (
          <UIButton onClick={handleApproveClick}>
            <CheckMarkIcon className="icon" />
            Approve ingest sheet
          </UIButton>
        )}
        <UIButton
          classes={showApproveButton ? `btn-clear` : ``}
          onClick={onOpenModal}
        >
          <TrashIcon className="icon" />
          Delete ingest sheet / job and start over
        </UIButton>
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
  status: PropTypes.string,
  history: ReactRouterPropTypes.history
};

export default withRouter(IngestSheetActionRow);
