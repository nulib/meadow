import React from "react";
import { useDropzone } from "react-dropzone";
import { formatBytes } from "@js/services/helpers";
import { IconFile } from "@js/components/Icon";
import { Notification } from "@nulib/admin-react-components";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
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

  const { getRootProps, getInputProps, isDragActive, isDragReject } =
    useDropzone({
      onDrop,
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
            <IconFile className="has-text-grey mr-3" />
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
        <Notification isSuccess>
          <button onClick={handleDelete} className="delete"></button>
          <p>
            <strong>{currentFile.name}</strong>
            <br />
            <small>{formatBytes(currentFile.size)}</small>
            <br />
            File uploaded successfully
          </p>
        </Notification>
      )}

      {currentFile && uploadProgress < 100 && (
        <Notification>
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
        </Notification>
      )}
    </section>
  );
}

WorkTabsPreservationFileSetDropzone.propTypes = {};

export default WorkTabsPreservationFileSetDropzone;
