import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { useDropzone } from "react-dropzone";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { useQuery } from "@apollo/client";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function DashboardsCsvImportModal({
  currentFile,
  handleClose,
  handleImportCsv,
  isOpen,
  setCurrentFile,
}) {
  //const [currentFile, setCurrentFile] = React.useState();
  const [displayError, setDisplayError] = React.useState();

  // Handle file drop
  const onDrop = React.useCallback((acceptedFiles) => {
    setCurrentFile(acceptedFiles[0]);
  }, []);
  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop });

  const handleCancelClick = () => {
    setCurrentFile(null);
    handleClose();
  };

  const handleImportClick = () => {
    handleImportCsv(currentFile);
  };

  return (
    <div className={`modal ${isOpen ? "is-active" : ""}`}>
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Import CSV file</p>
          <button
            className="delete"
            aria-label="close"
            onClick={handleClose}
          ></button>
        </header>
        <section className="modal-card-body">
          {displayError && (
            <p className="notification is-danger">{displayError}</p>
          )}

          <div
            {...getRootProps()}
            className="p-6 is-clickable has-text-centered"
            css={dropZone}
          >
            <input {...getInputProps()} />
            <p>
              <FontAwesomeIcon
                icon="file-csv"
                size="2x"
                className="has-text-grey mr-3"
              />
              {isDragActive
                ? "Drop the file here ..."
                : "Drag 'n' drop a file here, or click to select file"}
            </p>
          </div>
          {currentFile && (
            <React.Fragment>
              <p className="mt-5 pb-0 mb-0 subtitle">Current file</p>
              <table className="table is-fullwidth">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Path</th>
                    <th>Size</th>
                    <th>Type</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>{currentFile.name}</td>
                    <td>{currentFile.path}</td>
                    <td>{currentFile.size}</td>
                    <td>{currentFile.type}</td>
                  </tr>
                </tbody>
              </table>
            </React.Fragment>
          )}
        </section>
        <footer className="modal-card-foot is-justify-content-flex-end">
          <Button isText onClick={handleCancelClick}>
            Cancel
          </Button>
          <Button isPrimary onClick={handleImportClick} disabled={!currentFile}>
            Import
          </Button>
        </footer>
      </div>
    </div>
  );
}

DashboardsCsvImportModal.propTypes = {
  currentFile: PropTypes.object,
  handleClose: PropTypes.func,
  handleImportCsv: PropTypes.func,
  isOpen: PropTypes.bool,
  setCurrentFile: PropTypes.func,
};

export default DashboardsCsvImportModal;
