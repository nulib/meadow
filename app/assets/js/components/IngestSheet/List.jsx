import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useApolloClient, useMutation } from "@apollo/client/react";
import { DELETE_INGEST_SHEET } from "./ingestSheet.gql.js";
import UIModalDelete from "../UI/Modal/Delete";
import { toastWrapper } from "@js/services/helpers";
import UIIconText from "@js/components/UI/IconText";
import { formatDate, TEMP_USER_FRIENDLY_STATUS } from "@js/services/helpers";
import { IconAlert, IconTrashCan, IconView } from "@js/components/Icon";
import IngestSheetStatusTag from "@js/components/IngestSheet/StatusTag";
import { Notification } from "@nulib/design-system";

const IngestSheetList = ({ project, subscribeToIngestSheetStatusChanges }) => {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeModal, setActiveModal] = useState();

  useEffect(() => {
    subscribeToIngestSheetStatusChanges();
  }, []);

  const client = useApolloClient();
  const [
    deleteIngestSheet,
    { data: deleteIngestSheetData, error: deleteIngestSheetError },
  ] = useMutation(DELETE_INGEST_SHEET, {
    onCompleted({ deleteIngestSheet }) {
      toastWrapper("is-success", "Ingest sheet deleted successfully");
    },
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
        <Notification data-testid="no-ingest-sheets-notification">
          <UIIconText icon={<IconAlert />} isCentered>
            No ingest sheets
          </UIIconText>
        </Notification>
      )}

      {project.ingestSheets.length > 0 && (
        <div className="table-container">
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
              {project.ingestSheets.map(
                ({ id, title, status, updatedAt }, index) => (
                  <tr key={id + index}>
                    <td>
                      <Link to={`/project/${project.id}/ingest-sheet/${id}`}>
                        {title}
                      </Link>
                    </td>
                    <td className="has-text-right">{formatDate(updatedAt)}</td>
                    <td>
                      <IngestSheetStatusTag status={status}>
                        {TEMP_USER_FRIENDLY_STATUS[status]}
                      </IngestSheetStatusTag>
                    </td>
                    <td className="has-text-right">
                      {["APPROVED", "COMPLETED", "COMPLETED_ERROR"].indexOf(
                        status
                      ) > -1 && (
                        <Link
                          to={`/project/${project.id}/ingest-sheet/${id}`}
                          className="button is-light"
                        >
                          {<IconView />}{" "}
                          <span className="is-sr-only">View</span>
                        </Link>
                      )}
                      {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(
                        status
                      ) > -1 && (
                        <button
                          className="button is-light"
                          onClick={(e) => onOpenModal(e, { id, title })}
                        >
                          {<IconTrashCan />}{" "}
                          <span className="is-sr-only">Delete</span>
                        </button>
                      )}
                    </td>
                  </tr>
                )
              )}
            </tbody>
          </table>
          <UIModalDelete
            isOpen={modalOpen}
            handleClose={onCloseModal}
            handleConfirm={handleDeleteClick}
            thingToDeleteLabel={`Ingest Sheet ${
              activeModal ? activeModal.title : ""
            }`}
          />
        </div>
      )}
    </div>
  );
};

IngestSheetList.propTypes = {
  project: PropTypes.object.isRequired,
  subscribeToIngestSheetStatusChanges: PropTypes.func.isRequired,
};

export default IngestSheetList;
