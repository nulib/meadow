import { Button, Notification } from "@nulib/design-system";
import { FormProvider, useForm } from "react-hook-form";
import { GET_WORK, REPLACE_FILE_SET } from "@js/components/Work/work.gql.js";
import React, { useEffect, useState } from "react";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import { s3Location, toastWrapper } from "@js/services/helpers";
import { useLazyQuery, useMutation } from "@apollo/client";

import Error from "@js/components/UI/Error";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { IconAlert } from "@js/components/Icon";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UIIconText from "../../../UI/IconText";
import WorkTabsPreservationFileSetDropzone from "@js/components/Work/Tabs/Preservation/FileSetDropzone";
import classNames from "classnames";

const modalCss = css`
  z-index: 100;
`;

function WorkTabsPreservationReplaceFileSet({
  closeModal,
  fileset,
  isVisible,
  workId,
  workTypeId,
}) {
  const [currentFile, setCurrentFile] = useState();
  const [uploadProgress, setUploadProgress] = useState();
  const [s3UploadLocation, setS3UploadLocation] = useState();
  const [uploadError, setUploadError] = useState();
  const [stateXhr, setStateXhr] = useState(null);
  const [acceptedFileTypes, setAcceptedFileTypes] = React.useState("");

  useEffect(() => {
    if (!fileset.id) return;

    // Dynamically set some default form values since
    // the active fileset to replace may change by what user selects in the UI
    methods.setValue("label", fileset?.coreMetadata?.label || "");
    methods.setValue("description", fileset?.coreMetadata?.description || "");
  }, [fileset?.id]);

  const methods = useForm();

  // Get the presigned URL for the file upload
  const [
    getPresignedUrl,
    { error: urlError, loading: urlLoading, data: urlData },
  ] = useLazyQuery(GET_PRESIGNED_URL, {
    fetchPolicy: "no-cache",
    onCompleted: (data) => {
      uploadFile(data.presignedUrl.url);
    },
    onError(error) {
      console.error(`error`, error);
    },
  });

  // Set up and handle the GraphQL mutation to replace the fileset
  const [replaceFileSet, { loading, error, data }] = useMutation(
    REPLACE_FILE_SET,
    {
      onCompleted({ replaceFileSet }) {
        toastWrapper(
          "is-success",
          `FileSet record id: ${replaceFileSet.id} file was submitted successfully and ${replaceFileSet.coreMetadata.label} was submitted to the ingest pipeline.`
        );
        resetForm();
        closeModal();
      },
      onError(error) {
        console.error(`error:`, error);
        resetForm();
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

  // React Hook Form form submit handler function which calls the GraphQL mutation
  const handleSubmit = (data) => {
    replaceFileSet({
      variables: {
        id: fileset.id,
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
    setCurrentFile(null);
    setS3UploadLocation(null);
    setUploadProgress(0);
    setUploadError(null);
  };

  const handleSetFile = (file) => {
    setCurrentFile(file);
    if (file) {
      getPresignedUrl({
        variables: {
          uploadType: "FILE_SET",
          filename: file.name,
        },
        fetchPolicy: "no-cache",
      });
    }
  };

  const uploadFile = (presignedUrl) => {
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
        setS3UploadLocation(s3Location(presignedUrl));
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

    request.open("put", presignedUrl);
    request.setRequestHeader("Content-Type", "application/octet-stream");
    request.send(currentFile);
    setStateXhr(request);
  };

  return (
    <div
      className={classNames("modal", {
        "is-active": isVisible,
      })}
      css={modalCss}
      data-testid="replace-fileset-modal"
    >
      <div className="modal-background"></div>

      {urlError && (
        <div className="modal-card">
          <section className="modal-card-body">
            <Notification isDanger>Error retrieving presigned url</Notification>
          </section>
        </div>
      )}

      {!urlError && (
        <FormProvider {...methods}>
          <form
            onSubmit={methods.handleSubmit(handleSubmit)}
            data-testid="replace-fileset-form"
          >
            <div className="modal-card">
              <header className="modal-card-head">
                <p className="modal-card-title">Replace Fileset</p>
                <button
                  type="button"
                  className="delete"
                  aria-label="close"
                  onClick={handleCancel}
                ></button>
              </header>
              <section className="modal-card-body">
                <Notification isWarning>
                  <UIIconText icon={<IconAlert />}>
                    Replacing a fileset cannot be undone
                  </UIIconText>
                </Notification>
                {uploadError && (
                  <Notification isDanger>{uploadError}</Notification>
                )}
                {error && <Error error={error} />}

                <div className="block mt-5">
                  <WorkTabsPreservationFileSetDropzone
                    currentFile={currentFile}
                    acceptedFileTypes={acceptedFileTypes}
                    fileSetRole={fileset?.role?.id}
                    handleRemoveFile={resetForm}
                    handleSetFile={handleSetFile}
                    uploadProgress={uploadProgress}
                    workTypeId={workTypeId}
                  />
                </div>

                {s3UploadLocation && (
                  <>
                    <UIFormField label="Label">
                      <UIFormInput
                        isReactHookForm
                        required
                        label="Label"
                        data-testid="fileset-label-input"
                        name="label"
                        placeholder="Fileset label"
                      />
                    </UIFormField>

                    <UIFormField label="Description">
                      <UIFormInput
                        isReactHookForm
                        required
                        label="Description"
                        data-testid="fileset-description-input"
                        name="description"
                        placeholder="Description of the Fileset"
                      />
                    </UIFormField>
                  </>
                )}
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
                      Upload File
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

WorkTabsPreservationReplaceFileSet.propTypes = {
  closeModal: PropTypes.func,
  fileset: PropTypes.object,
  isVisible: PropTypes.bool,
  workId: PropTypes.string,
  workTypeId: PropTypes.oneOf(["IMAGE", "AUDIO", "VIDEO"]),
};

export default WorkTabsPreservationReplaceFileSet;
