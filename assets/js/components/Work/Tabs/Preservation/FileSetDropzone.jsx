import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useDropzone } from "react-dropzone";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function WorkTabsPreservationFileSetDropzone({ currentFile, handleSetFile }) {
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
    accept: "image/tiff, image/jpeg",
    maxFiles: 1,
  });

  return (
    <div>
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
    </div>
  );
}

WorkTabsPreservationFileSetDropzone.propTypes = {};

export default WorkTabsPreservationFileSetDropzone;
