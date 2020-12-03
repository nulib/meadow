import React, { useState } from "react";
import UIModalDelete from "../UI/Modal/Delete";
import { DELETE_INGEST_SHEET, INGEST_SHEETS } from "./ingestSheet.gql";
import { useMutation, useApolloClient } from "@apollo/client";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { toastWrapper } from "../../services/helpers";
import { Button } from "@nulib/admin-react-components";

const IngestSheetActionRow = ({ projectId, sheetId, status, title }) => {
  const history = useHistory();
  const client = useApolloClient();

  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

  const [deleteIngestSheet, { data: deleteIngestSheetData }] = useMutation(
    DELETE_INGEST_SHEET,
    {
      update(cache, { data: { deleteIngestSheet } }) {
        try {
          const { project } = client.readQuery({
            query: INGEST_SHEETS,
            variables: { projectId },
          });
          const index = project.ingestSheets.findIndex(
            (ingestSheet) => ingestSheet.id === deleteIngestSheet.id
          );
          project.ingestSheets.splice(index, 1);
          client.writeQuery({
            query: INGEST_SHEETS,
            data: { project },
          });
        } catch (error) {
          console.log("Error reading from cache", error);
        }
      },
      onCompleted({ deleteIngestSheet }) {
        toastWrapper(
          "is-success",
          `Ingest sheet ${title} deleted successfully`
        );
        history.push(`/project/${projectId}`);
      },
    }
  );

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
        {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) >
          -1 && (
          <Button onClick={onOpenModal}>
            <span className="icon">
              <FontAwesomeIcon icon="trash" />
            </span>{" "}
            <span>Delete and start over</span>
          </Button>
        )}
      </div>

      <UIModalDelete
        isOpen={deleteModalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Ingest Sheet ${title}`}
      />
    </>
  );
};

IngestSheetActionRow.propTypes = {
  projectId: PropTypes.string,
  sheetId: PropTypes.string,
  status: PropTypes.string,
  title: PropTypes.string,
};

export default IngestSheetActionRow;
