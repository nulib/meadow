import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useDropzone } from "react-dropzone";
import { formatBytes } from "@js/services/helpers";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function WorkTabsPreservationFileSetDropzone({
  currentFile,
  handleSetFile,
  uploadProgress,
}) {
  // Handle file drop
  const onDrop = React.useCallback((acceptedFiles) => {
    handleSetFile(acceptedFiles[0]);
  }, []);

  const {
    getRootProps,
    getInputProps,
    isDragActive,
    isDragReject,
  } = useDropzone({
    onDrop,
    accept: "image/tiff, image/jpeg, image/jpg",
    multiple: false,
  });

  const handleDelete = () => {
    handleSetFile(null);
  };

  return (
    <section className="modal-card-body">
      {!uploadProgress && (
        <div
          {...getRootProps()}
          className="p-6 is-clickable has-text-centered"
          css={dropZone}
        >
          <input {...getInputProps()} />
          <p>
            <FontAwesomeIcon
              icon="file-image"
              size="2x"
              className="has-text-grey mr-3"
            />
            {!isDragActive &&
              "Drag 'n' drop a file here, or click to select file"}
            {isDragActive &&
              !isDragReject &&
              "Drag 'n' drop a file here, or click to select file"}
            {isDragReject && "File type not accepted, sorry!"}
          </p>
        </div>
      )}

      {currentFile && uploadProgress === 100 && (
        <div className="notification is-light is-success">
          <button onClick={handleDelete} className="delete"></button>
          <p>
            <strong>{currentFile.name}</strong>
            <br />
            <small>{formatBytes(currentFile.size)}</small>
            <br />
            File uploaded successfully
          </p>
        </div>
      )}

      {currentFile && uploadProgress < 100 && (
        <div className="notification is-light">
          <p>
            <strong>{currentFile.name}</strong>
            <br />
            <small>Uploading {formatBytes(currentFile.size)}</small>
          </p>
          <progress
            className="progress is-primary is-small"
            value={uploadProgress}
            max="100"
          ></progress>
          <p>({Math.round(Number(uploadProgress))}%)</p>
        </div>
      )}
    </section>
  );
}

WorkTabsPreservationFileSetDropzone.propTypes = {};

export default WorkTabsPreservationFileSetDropzone;
