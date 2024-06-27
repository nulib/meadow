import useAcceptedMimeTypes from "@js/hooks/useAcceptedMimeTypes";
import { Button } from "@nulib/design-system";
import {
  LIST_INGEST_BUCKET_OBJECTS,
} from "@js/components/Work/work.gql.js";
import React, { useState } from "react";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import { useQuery } from "@apollo/client";
import { FaSpinner } from "react-icons/fa";
import { formatBytes } from "@js/services/helpers";

import Error from "@js/components/UI/Error";
import UIFormInput from "@js/components/UI/Form/Input.jsx";

const tableContainerCss = css`
  max-height: 30vh;
  overflow-y: auto;
`;

const fileRowCss = css`
  cursor: pointer;
`;

const selectedRowCss = css`
  background-color: #f0f8ff !important;
`;

const colHeaders = ["File Key", "Size", "Mime Type"];

const S3ObjectPicker = ({ onFileSelect, fileSetRole, workTypeId, defaultPrefix = "" }) => {
  const [prefix, setPrefix] = useState(defaultPrefix);
  const [selectedFile, setSelectedFile] = useState(null);
  const [error, _setError] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  const { isFileValid } = useAcceptedMimeTypes();

  const { loading: queryLoading, error: queryError, data, refetch } = useQuery(LIST_INGEST_BUCKET_OBJECTS, {
    variables: { prefix }
  });

  const handleClear = () => {
    setPrefix(defaultPrefix);
    refetch({ prefix: defaultPrefix });
  };

  const handlePrefixChange = async (e) => {
    const inputValue = e.target.value;
    const newPrefix = inputValue.startsWith(defaultPrefix) ? inputValue : defaultPrefix + inputValue;
    setPrefix(newPrefix);
    await refetch({ prefix: newPrefix });
  };

  const handleRefresh = async () => {
    await refetch({ prefix: prefix });
  };

  const handleFileClick = (fileSet) => {
    setSelectedFile(fileSet.key);
    onFileSelect(fileSet);
    // Reset upload progress and isUploading state when selecting an S3 object
    setUploadProgress(0);
    setIsUploading(false);
  };

  const handleDragAndDrop = (file) => {
    // Simulating file upload process
    setIsUploading(true);
    setUploadProgress(0);
    const interval = setInterval(() => {
      setUploadProgress((prevProgress) => {
        if (prevProgress >= 100) {
          clearInterval(interval);
          setIsUploading(false);
          return 100;
        }
        return prevProgress + 10;
      });
    }, 500);
  };

  if (queryLoading) return <FaSpinner className="spinner" />;
  if (queryError) return <Error error={queryError} />;

  return (
    <div className="file-picker">
      <div className="drag-drop-area" onDrop={handleDragAndDrop}>
        {/* Drag and drop area */}
        <p>Drag 'n' drop a file here, or click to select file</p>
        {isUploading && (
          <div className="progress-bar">
            <div className="progress" style={{ width: `${uploadProgress}%` }}></div>
          </div>
        )}
      </div>
      <UIFormInput
        placeholder="Enter prefix"
        name="prefixSearch"
        label="Prefix Search"
        onChange={handlePrefixChange}
        value={prefix}
      />
      <div className="buttons mt-2">
        <Button onClick={handleClear}>Clear</Button>
        <Button onClick={handleRefresh}>Refresh</Button>
      </div>
      {error && <div className="error">{error}</div>}
      {data && data.ListIngestBucketObjects && (
        <div className="table-container" css={tableContainerCss}>
          <table className="table is-striped is-fullwidth">
            <thead>
              <tr>
                {colHeaders.map((col) => (
                  <th key={col}>{col}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.ListIngestBucketObjects.filter(file => {
                const { isValid } = isFileValid(fileSetRole, workTypeId, file.mimeType);
                return isValid;
              }).map((fileSet, index) => (
                <tr
                  key={index}
                  onClick={() => handleFileClick(fileSet)}
                  className={selectedFile === fileSet.key ? "selected" : ""}
                  css={[fileRowCss, selectedFile === fileSet.key && selectedRowCss]}
                >
                  <td>{fileSet.key}</td>
                  <td>{formatBytes(fileSet.size)}</td>
                  <td>{fileSet.mimeType}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default S3ObjectPicker;