import React from "react";
import PropTypes from "prop-types";
import { Button, Notification } from "@nulib/design-system";
import { useDropzone } from "react-dropzone";
import { IconCsv } from "@js/components/Icon";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { CREATE_INGEST_SHEET } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { GET_PROJECT } from "@js/components/Project/project.gql.js";
import { useMutation, useQuery } from "@apollo/client/react";
import { s3Location, toastWrapper } from "@js/services/helpers";
import { useHistory } from "react-router-dom";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const dropZone = css`
  background: #efefef;
  border: 3px dashed #ccc;
`;

function ProjectIngestSheetModal({ closeModal, isHidden, projectId }) {
  const history = useHistory();
  const [currentFile, setCurrentFile] = React.useState();
  const [displayError, setDisplayError] = React.useState();

  const {
    loading: urlLoading,
    error: urlError,
    data: urlData,
  } = useQuery(GET_PRESIGNED_URL, {
    variables: { uploadType: "INGEST_SHEET" },
    fetchPolicy: "no-cache",
  });
  if (urlError) {
    setDisplayError(urlError.toString());
  }

  const [createIngestSheet, { data, loading, error }] = useMutation(
    CREATE_INGEST_SHEET,
    {
      onCompleted({ createIngestSheet }) {
        toastWrapper(
          "is-success",
          `Ingest Sheet ${createIngestSheet.title} created successfully`
        );
        closeModal();
        history.push(
          `/project/${projectId}/ingest-sheet/${createIngestSheet.id}`
        );
      },
      onError({ graphQLErrors, networkError }) {
        let errorStrings = [];
        if (graphQLErrors?.length > 0) {
          errorStrings = graphQLErrors.map(
            ({ message, details }) =>
              `${message}: ${details && details.title ? details.title : ""}`
          );
        }
        toastWrapper(
          "is-danger",
          errorStrings.length > 0
            ? errorStrings.join(" \n ")
            : "Unknown error occurred creating the Ingest sheet"
        );
        setCurrentFile(null);
        closeModal();
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

  const handleCancelClick = () => {
    setCurrentFile(null);
    closeModal();
  };

  const handleUploadClick = async () => {
    if (currentFile) {
      uploadToS3()
        .then(
          // Resolve callback
          () => {
            createIngestSheet({
              variables: {
                title: currentFile.name,
                projectId,
                filename: s3Location(urlData.presignedUrl.url),
              },
            });
          },
          // Error callback
          (uploadToS3Error) => {
            toastWrapper(
              "is-danger",
              `Error uploading file to S3: ${uploadToS3Error}`
            );
          }
        )
        .catch((e) => {
          console.error(
            "Shouldn't get here, some there was an error uploading to S3 and/or creating an Ingest Sheet",
            e
          );
        });
    } else {
      toastWrapper("is-danger", `Choose a file to ingest`);
    }
  };

  function uploadToS3() {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        fetch(urlData.presignedUrl.url, {
          method: "PUT",
          headers: { "Content-Type": currentFile.type },
          body: event.target.result,
        })
          .then((data) => {
            if (data.ok) {
              resolve();
            } else {
              reject(`${data.status}: ${data.statusText}`);
            }
          })
          .catch((error) => {
            console.error(
              "Should never reach here, but an error fetching the presignedUrl",
              error
            );
          });
      };
      reader.readAsText(currentFile);
    });
  }

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
          {displayError && <Notification isDanger>{displayError}</Notification>}

          <div
            {...getRootProps()}
            className="p-6 is-clickable has-text-centered"
            css={dropZone}
          >
            <input {...getInputProps()} />
            <p>
              <IconCsv icon="file-csv" className="has-text-grey mr-3" />
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
