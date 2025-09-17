import { Button, Notification } from "@nulib/design-system";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";

import { IconFile } from "@js/components/Icon";
import React from "react";
import { formatBytes } from "@js/services/helpers";
import useAcceptedMimeTypes from "@js/hooks/useAcceptedMimeTypes";
import { useDropzone } from "react-dropzone";

const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function WorkTabsPreservationFileSetDropzone({
  currentFile,
  fileSetRole,
  handleRemoveFile,
  handleSetFile,
  uploadProgress,
  workTypeId,
}) {
  const { isFileValid } = useAcceptedMimeTypes();

  function mimeTypeValidator(file) {
    const { isValid, code, message } = isFileValid(
      fileSetRole,
      workTypeId,
      file.type,
    );

    // Dropzone validator: null means valid
    if (isValid) {
      return null;
    }

    // Validation failed, give details
    return {
      code,
      message,
    };
  }

  // Handle file drop
  const onDrop = React.useCallback((acceptedFiles) => {
    handleSetFile(acceptedFiles[0]);
  }, []);

  const { acceptedFiles, fileRejections, getRootProps, getInputProps } =
    useDropzone({
      onDrop,
      multiple: false,
      validator: mimeTypeValidator,
    });

  const acceptedFileItems = acceptedFiles.map((file) => (
    <li key={file.path}>
      {file.path} - {formatBytes(file.size)} bytes
    </li>
  ));

  const fileRejectionItems = fileRejections.map(({ file, errors }) => (
    <li key={file.path}>
      {file.path} - {formatBytes(file.size)} bytes
      <ul>
        {errors.map((e) => (
          <li key={e.code}>{e.message}</li>
        ))}
      </ul>
    </li>
  ));

  return (
    <section>
      {!uploadProgress && (
        <div
          {...getRootProps()}
          className="p-6 is-clickable has-text-centered"
          css={dropZone}
        >
          <input {...getInputProps()} />
          <p>
            <IconFile className="has-text-grey mr-3" />
            Drag and drop a file here, or click to select file
          </p>
        </div>
      )}

      {fileRejectionItems.length > 0 && (
        <div className="block mt-4">
          <Notification isDanger>
            <p>
              <strong>Rejected files</strong>
            </p>
            <ul>{fileRejectionItems}</ul>
          </Notification>
        </div>
      )}

      {currentFile && uploadProgress === 100 && (
        <>
          <Notification isSuccess>
            <h4>
              <strong>File uploaded successfully</strong>
            </h4>
            <ul className="block">{acceptedFileItems}</ul>
          </Notification>
          <p className="has-text-right">
            <a onClick={handleRemoveFile}>Remove file</a>
          </p>
        </>
      )}

      {currentFile && uploadProgress < 100 && (
        <Notification>
          <h4>Accepted files</h4>
          <ul>{acceptedFileItems}</ul>
          <small>Uploading {formatBytes(currentFile.size)}</small>
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
