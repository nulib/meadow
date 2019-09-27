import React, { useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toast } from "react-toastify";
import { GET_INGEST_SHEETS, DELETE_INGEST_SHEET } from "./ingestSheet.query";
import { useApolloClient, useMutation } from "@apollo/react-hooks";
import UIModalDelete from "../UI/Modal/Delete";
import TrashIcon from "../../../css/fonts/zondicons/trash.svg";

const IngestSheetList = ({ projectId }) => {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeModal, setActiveModal] = useState();
  const { loading, error, data } = useQuery(GET_INGEST_SHEETS, {
    variables: { projectId }
  });
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

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;
  if (deleteIngestSheetError) {
    toast(`Error: ${deleteIngestSheetError.message}`);
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
      {data.project.ingestSheets.length === 0 && (
        <p data-testid="no-ingest-sheets-notification">
          No ingest sheets are found.
        </p>
      )}

      {data.project.ingestSheets.length > 0 && (
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
              {data.project.ingestSheets.map(
                ({ id, name, filename, status, updatedAt }) => (
                  <tr key={id}>
                    <td>
                      <Link to={`/project/${projectId}/ingest-sheet/${id}`}>
                        {name}
                      </Link>
                    </td>
                    <td>{updatedAt}</td>
                    <td>{status}</td>
                    <td className="text-right">
                      <button onClick={e => onOpenModal(e, id)}>
                        <TrashIcon className="icon cursor-pointer" />
                      </button>
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
            thingToDeleteLabel={`Ingest Sheet`}
          />
        </>
      )}
    </div>
  );
};

IngestSheetList.propTypes = {
  projectId: PropTypes.string.isRequired
};

export default IngestSheetList;
