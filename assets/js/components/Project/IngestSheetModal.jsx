import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { useDropzone } from "react-dropzone";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import axios from "axios";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { CREATE_INGEST_SHEET } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { GET_PROJECT } from "@js/components/Project/project.gql.js";
import { useQuery, useMutation } from "@apollo/client";
import { toastWrapper } from "@js/services/helpers";
import { useHistory } from "react-router-dom";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function ProjectIngestSheetModal({ closeModal, isHidden, projectId }) {
  const history = useHistory();
  const [currentFile, setCurrentFile] = React.useState();

  const { loading: urlLoading, error: urlError, data: urlData } = useQuery(
    GET_PRESIGNED_URL,
    {
      fetchPolicy: "no-cache",
    }
  );

  const [createIngestSheet, { data, loading, error }] = useMutation(
    CREATE_INGEST_SHEET,
    {
      onCompleted({ createIngestSheet }) {
        toastWrapper(
          "is-success",
          `Ingest Sheet ${currentFile.name} created successfully`
        );
        closeModal();
        history.push(
          `/project/${projectId}/ingest-sheet/${createIngestSheet.id}`
        );
      },
      onError({ createIngestSheet }) {
        console.error("Error creating Ingest sheet", createIngestSheet);
        toastWrapper("is-danger", `Error uploading Ingest Sheet`);
      },
      refetchQueries(mutationResult) {
        return [
          {
            query: GET_PROJECT,
            variables: { projectId: projectId },
          },
        ];
      },
    }
  );

  // Handle file drop
  const onDrop = React.useCallback((acceptedFiles) => {
    setCurrentFile(acceptedFiles[0]);
  }, []);
  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop });

  const handleUploadClick = async () => {
    if (currentFile) {
      await uploadToS3();
      await createIngestSheet({
        variables: {
          title: currentFile.name,
          projectId,
          filename: `s3://${urlData.presignedUrl.url
            .split("?")[0]
            .split("/")
            .slice(-3)
            .join("/")}`,
        },
      });
    } else {
      toastWrapper("is-danger", `Choose a file to ingest`);
    }
  };

  const uploadToS3 = () => {
    return new Promise((resolve, _reject) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        const headers = { "Content-Type": currentFile.type };
        axios
          .put(urlData.presignedUrl.url, event.target.result, {
            headers: headers,
          })
          .then((_) => resolve())
          .catch((error) => {
            console.error(error);
            toastWrapper("is-danger", `Error uploading file to S3: ${error}`);
            resolve();
          });
      };
      reader.readAsText(currentFile);
    });
  };

  if (urlLoading) {
    return <p>...Loading</p>;
  }
  if (urlError) {
    return <p>Error loading presigned url</p>;
  }

  return (
    <div className={`modal ${isHidden ? "" : "is-active"}`}>
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Add Ingest Sheet</p>
          <button
            className="delete"
            aria-label="close"
            onClick={closeModal}
          ></button>
        </header>
        <section className="modal-card-body">
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
                ? "Drop the files here ..."
                : "Drag 'n' drop a file here, or click to select files"}
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
          <Button isText onClick={closeModal}>
            Cancel
          </Button>
          <Button isPrimary onClick={handleUploadClick} disabled={!currentFile}>
            Upload
          </Button>
        </footer>
      </div>
    </div>
  );
}

ProjectIngestSheetModal.propTypes = {
  closeModal: PropTypes.func,
  isHidden: PropTypes.bool,
  projectId: PropTypes.string,
};

export default ProjectIngestSheetModal;
