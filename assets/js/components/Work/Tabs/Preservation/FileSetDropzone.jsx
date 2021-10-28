import React from "react";
import { useDropzone } from "react-dropzone";
import { formatBytes } from "@js/services/helpers";
import { IconFile } from "@js/components/Icon";
import { Notification } from "@nulib/admin-react-components";
import useAcceptedMimeTypes from "@js/hooks/useAcceptedMimeTypes";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
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
      file.type
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
            Drag 'n' drop a file here, or click to select file
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
        <Notification isSuccess>
          <button onClick={handleRemoveFile} className="delete"></button>
          <h4>
            <strong>File uploaded successfully</strong>
          </h4>
          <ul>{acceptedFileItems}</ul>
        </Notification>
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
