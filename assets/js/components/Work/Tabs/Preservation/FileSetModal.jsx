import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { GET_WORK, INGEST_FILE_SET } from "@js/components/Work/work.gql.js";
import { useQuery, useMutation } from "@apollo/client";
import { s3Location, toastWrapper } from "@js/services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import WorkTabsPreservationFileSetDropzone from "@js/components/Work/Tabs/Preservation/FileSetDropzone";
import WorkTabsPreservationFileSetForm from "@js/components/Work/Tabs/Preservation/FileSetForm";
import Error from "@js/components/UI/Error";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const modalCss = css`
  z-index: 100;
`;

function WorkTabsPreservationFileSetModal({ closeModal, isVisible, workId }) {
  const [currentFile, setCurrentFile] = useState();
  const [uploadProgress, setUploadProgress] = useState();
  const [s3UploadLocation, setS3UploadLocation] = useState();
  const [uploadError, setUploadError] = useState();
  const [stateXhr, setStateXhr] = useState(null);

  const defaultValues = {
    accessionNumber: "",
    label: "",
    description: "",
    role: { id: "A", scheme: "FILE_SET_ROLE" },
  };

  const methods = useForm({
    defaultValues: defaultValues,
    shouldUnregister: false,
  });

  const { loading: urlLoading, error: urlError, data: urlData } = useQuery(
    GET_PRESIGNED_URL,
    {
      variables: { uploadType: "FILE_SET" },
      fetchPolicy: "no-cache",
    }
  );

  const [ingestFileSet, { loading, error, data }] = useMutation(
    INGEST_FILE_SET,
    {
      onCompleted({ ingestFileSet }) {
        toastWrapper(
          "is-success",
          `FileSet record id: ${ingestFileSet.id} created successfully and ${ingestFileSet.coreMetadata.original_filename} was submitted to the ingest pipeline.`
        );
        resetForm();
        closeModal();
      },
      onError(error) {
        // bug with this error not clearing/resetting
        // https://github.com/apollographql/apollo-feature-requests/issues/170
      },
      refetchQueries: [
        {
          query: GET_WORK,
          variables: { id: workId },
        },
      ],
      awaitRefetchQueries: true,
    }
  );

  const handleSubmit = (data) => {
    ingestFileSet({
      variables: {
        accession_number: data.accessionNumber,
        workId,
        role: { id: data.role, scheme: "FILE_SET_ROLE" },
        coreMetadata: {
          description: data.description,
          label: data.label,
          original_filename: currentFile.name,
          location: s3UploadLocation,
        },
      },
    });
  };

  const handleCancel = () => {
    if (stateXhr != null) stateXhr.abort();
    resetForm();
    closeModal();
  };

  const resetForm = () => {
    methods.reset();
    setCurrentFile(null);
    setS3UploadLocation(null);
    setUploadProgress(0);
    setUploadError(null);
  };

  const handleSetFile = (file) => {
    setCurrentFile(file);
    if (file != null) {
      uploadFile(file);
    } else {
      setUploadProgress(0);
    }
  };

  const uploadFile = (file) => {
    let request = new XMLHttpRequest();

    request.upload.addEventListener("progress", function (e) {
      let percent_completed = (e.loaded / e.total) * 100;
      setUploadProgress(percent_completed);
    });

    request.addEventListener("error", function (e) {
      setUploadError("Error uploading file to S3");
      setCurrentFile(null);
    });

    request.addEventListener("load", function (e) {
      if (request.status === 200) {
        setS3UploadLocation(s3Location(urlData.presignedUrl.url));
      } else {
        setUploadError(
          `Error uploading file to S3. Response status: ${request.status}`
        );
        setCurrentFile(null);
      }
    });

    request.addEventListener("abort", function (e) {
      console.log("Received abort event. Cancelling upload");
    });

    request.open("put", urlData.presignedUrl.url);
    request.setRequestHeader("Content-Type", "multipart/form-data");
    request.send(file);
    setStateXhr(request);
  };

  if (urlLoading) return <p>Presigned URL Loading</p>;

  return (
    <div className={`modal ${isVisible ? "is-active" : ""}`} css={modalCss}>
      <div className="modal-background"></div>

      {urlError ? (
        <div className="modal-card">
          <section className="modal-card-body">
            <div className="notification is-danger">
              Error retrieving presigned url
            </div>
          </section>
        </div>
      ) : (
        <FormProvider {...methods}>
          <form
            onSubmit={methods.handleSubmit(handleSubmit)}
            data-testid="fileset-form"
          >
            <div className="modal-card">
              <header className="modal-card-head">
                <p className="modal-card-title">Add FileSet to Work</p>
                <button
                  type="button"
                  className="delete"
                  aria-label="close"
                  onClick={handleCancel}
                ></button>
              </header>
              <section className="modal-card-body">
                {uploadError && (
                  <div className="notification is-danger">{uploadError}</div>
                )}
                {error && <Error error={error} />}
                <WorkTabsPreservationFileSetDropzone
                  currentFile={currentFile}
                  handleSetFile={handleSetFile}
                  uploadProgress={uploadProgress}
                />

                <WorkTabsPreservationFileSetForm
                  s3UploadLocation={s3UploadLocation}
                />
              </section>

              <footer className="modal-card-foot is-justify-content-flex-end">
                {s3UploadLocation && (
                  <>
                    <Button
                      isText
                      type="button"
                      onClick={() => {
                        handleCancel();
                      }}
                      data-testid="cancel-button"
                    >
                      Cancel
                    </Button>
                    <Button isPrimary type="submit" data-testid="submit-button">
                      Ingest fileset
                    </Button>
                  </>
                )}
              </footer>
            </div>
          </form>
        </FormProvider>
      )}
    </div>
  );
}

WorkTabsPreservationFileSetModal.propTypes = {
  closeModal: PropTypes.func,
  isVisible: PropTypes.bool,
  workId: PropTypes.string,
};

export default WorkTabsPreservationFileSetModal;
