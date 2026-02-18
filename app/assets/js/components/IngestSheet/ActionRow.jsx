import React, { useState } from "react";
import UIModalDelete from "../UI/Modal/Delete";
import { DELETE_INGEST_SHEET } from "./ingestSheet.gql";
import { useMutation } from "@apollo/client/react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { Button } from "@nulib/design-system";
import { IconTrashCan } from "@js/components/Icon";

const IngestSheetActionRow = ({ projectId, sheetId, status, title }) => {
  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

  const [deleteIngestSheet] = useMutation(DELETE_INGEST_SHEET, {
    update(cache, { data: { deleteIngestSheet } }) {
      try {
        cache.modify({
          id: cache.identify({ __typename: "Project", id: projectId }),
          fields: {
            ingestSheets(existingIngestSheetRefs, { readField }) {
              return existingIngestSheetRefs.filter(
                (ingestSheetRef) =>
                  deleteIngestSheet.id !== readField("id", ingestSheetRef)
              );
            },
          },
        });
      } catch (error) {
        console.error("Error reading from cache", error);
      }
    },
    onCompleted() {
      history.push(`/project/${projectId}`);
    },
  });

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
      <div className="buttons">
        {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) >
          -1 && (
          <Button onClick={onOpenModal}>
            <IconTrashCan />
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
