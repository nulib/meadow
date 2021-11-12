import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button, Notification } from "@nulib/design-system";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { GET_WORK, INGEST_FILE_SET } from "@js/components/Work/work.gql.js";
import { useLazyQuery, useMutation } from "@apollo/client";
import { s3Location, toastWrapper } from "@js/services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import WorkTabsPreservationFileSetDropzone from "@js/components/Work/Tabs/Preservation/FileSetDropzone";
import WorkTabsPreservationFileSetForm from "@js/components/Work/Tabs/Preservation/FileSetForm";
import Error from "@js/components/UI/Error";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormSelect from "@js/components/UI/Form/Select.jsx";
import { useCodeLists } from "@js/context/code-list-context";
import useAcceptedMimeTypes from "@js/hooks/useAcceptedMimeTypes";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const modalCss = css`
  z-index: 100;
`;

function WorkTabsPreservationFileSetModal({
  closeModal,
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

  const codeLists = useCodeLists();

  const defaultValues = {
    accessionNumber: "",
    label: "",
    description: "",
  };

  const methods = useForm({
    defaultValues: defaultValues,
    shouldUnregister: false,
  });

  // Watch form select element fileSetRole for changes, to determine what types
  // of files are allowed to upload
  const watchRole = methods.watch("fileSetRole");

  React.useEffect(() => {
    if (!watchRole) return;
    const mimeTypes = useAcceptedMimeTypes({
      fileSetRole: watchRole,
      workTypeId,
    });
    setAcceptedFileTypes(mimeTypes);
  }, [watchRole]);

  const [getPresignedUrl, { urlError, urlLoading, urlData }] = useLazyQuery(
    GET_PRESIGNED_URL,
    {
      fetchPolicy: "no-cache",
      onCompleted: (data) => {
        uploadFile(data.presignedUrl.url);
      },
      onError(error) {
        console.error(`error`, error);
      },
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
        console.error(`error:`, error);
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
        role: { id: watchRole, scheme: "FILE_SET_ROLE" },
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
    request.setRequestHeader("Content-Type", "multipart/form-data");
    request.send(currentFile);
    setStateXhr(request);
  };

  return (
    <div
      className={classNames("modal", {
        "is-active": isVisible,
      })}
      css={modalCss}
    >
      <div className="modal-background"></div>

      {urlError ? (
        <div className="modal-card">
          <section className="modal-card-body">
            <Notification isDanger>Error retrieving presigned url</Notification>
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
                <p className="modal-card-title">Add Fileset to Work</p>
                <button
                  type="button"
                  className="delete"
                  aria-label="close"
                  onClick={handleCancel}
                ></button>
              </header>
              <section className="modal-card-body">
                {uploadError && (
                  <Notification isDanger>{uploadError}</Notification>
                )}
                {error && <Error error={error} />}

                <UIFormField label="Fileset Role">
                  <UIFormSelect
                    isReactHookForm
                    name="fileSetRole"
                    label="Fileset Role"
                    options={codeLists?.fileSetRoleData?.codeList}
                    required
                    showHelper
                    disabled={Boolean(s3UploadLocation)}
                  />
                </UIFormField>

                {watchRole && (
                  <div className="block">
                    <WorkTabsPreservationFileSetDropzone
                      currentFile={currentFile}
                      acceptedFileTypes={acceptedFileTypes}
                      fileSetRole={watchRole}
                      handleRemoveFile={resetForm}
                      handleSetFile={handleSetFile}
                      uploadProgress={uploadProgress}
                      workTypeId={workTypeId}
                    />
                  </div>
                )}

                {s3UploadLocation && (
                  <WorkTabsPreservationFileSetForm
                    s3UploadLocation={s3UploadLocation}
                  />
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
  workTypeId: PropTypes.oneOf(["IMAGE", "AUDIO", "VIDEO"]),
};

export default WorkTabsPreservationFileSetModal;
