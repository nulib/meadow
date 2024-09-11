import * as Dialog from "@radix-ui/react-dialog";
import {
  DialogClose,
  DialogContent,
  DialogFooter,
  DialogOverlay,
  DialogTitle
} from "@js/components/UI/Dialog/Dialog.styled";
import { Button, Icon, Notification } from "@nulib/design-system";
import { FormProvider, useForm } from "react-hook-form";
import { GET_WORK, INGEST_FILE_SET } from "@js/components/Work/work.gql.js";
import React, { useState, useEffect } from "react";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import { getFileNameFromS3Uri, s3Location, toastWrapper } from "@js/services/helpers";
import { useLazyQuery, useMutation } from "@apollo/client";

import Error from "@js/components/UI/Error";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormSelect from "@js/components/UI/Form/Select.jsx";
import WorkTabsPreservationFileSetDropzone from "@js/components/Work/Tabs/Preservation/FileSetDropzone";
import WorkTabsPreservationFileSetForm from "@js/components/Work/Tabs/Preservation/FileSetForm";
import useAcceptedMimeTypes from "@js/hooks/useAcceptedMimeTypes";
import { useCodeLists } from "@js/context/code-list-context";
import S3ObjectPicker from "@js/components/Work/Tabs/Preservation/S3ObjectPicker"

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
  const [acceptedFileTypes, setAcceptedFileTypes] = useState("");
  const [uploadMethod, setUploadMethod] = useState(null);

  const codeLists = useCodeLists();

  const defaultValues = {
    accessionNumber: "",
    label: "",
    description: "",
    fileSetRole: "",
  };

  const methods = useForm({
    defaultValues: defaultValues,
    shouldUnregister: false,
  });

  const watchRole = methods.watch("fileSetRole");

  const handleSelectS3Object = (s3Object) => {
    setCurrentFile({
      location: s3Object.key,
      name: getFileNameFromS3Uri(s3Object.key),
    });
    setS3UploadLocation(s3Object.key);
    setUploadMethod('s3');
  };

  useEffect(() => {
    if (!watchRole) return;
    const mimeTypes = useAcceptedMimeTypes({
      fileSetRole: watchRole,
      workTypeId,
    });
    setAcceptedFileTypes(mimeTypes);
  }, [watchRole, workTypeId]);

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

  const [ingestFileSet, { loading, error, data }] = useMutation(
    INGEST_FILE_SET,
    {
      onCompleted({ ingestFileSet }) {
        toastWrapper(
          "is-success",
          `FileSet record id: ${ingestFileSet.id} created successfully and ${ingestFileSet.coreMetadata.original_filename} was submitted to the ingest pipeline.`,
        );
        resetForm();
        closeModal();
      },
      onError(error) {
        console.error(`error:`, error);
        resetForm();
      },
      refetchQueries: [
        {
          query: GET_WORK,
          variables: { id: workId },
        },
      ],
      awaitRefetchQueries: true,
    },
  );

  const handleSubmit = (data) => {
    const mutationInput = {
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
      }
    }
    ingestFileSet(mutationInput);
  };

  const resetForm = () => {
    methods.reset(defaultValues);
    setCurrentFile(null);
    setS3UploadLocation(null);
    setUploadProgress(0);
    setUploadError(null);
    setUploadMethod(null);
    setAcceptedFileTypes("");
  };

  const handleCancel = () => {
    if (stateXhr != null) stateXhr.abort();
    resetForm();
    closeModal();
  };

  const handleCloseModal = () => {
    resetForm();
    closeModal();
  };

  const handleSetFile = (file) => {
    setCurrentFile(file);
    setUploadMethod('dragdrop');
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
          `Error uploading file to S3. Response status: ${request.status}`,
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
    <Dialog.Root open={isVisible} onOpenChange={handleCloseModal}>
      <Dialog.Portal>
        <DialogOverlay />
        <DialogContent data-testid="add-file-set">
          <DialogClose>
            <Icon isSmall aria-label="Close">
              <Icon.Close />
            </Icon>
          </DialogClose>
          <DialogTitle css={{ textAlign: "left" }}>
            Add Fileset to Work
          </DialogTitle>

          {urlError ? (
            <div>
              <section>
                <Notification isDanger>Error retrieving presigned url</Notification>
              </section>
            </div>
          ) : (
            <FormProvider {...methods}>
              <form
                onSubmit={methods.handleSubmit(handleSubmit)}
                data-testid="fileset-form"
              >
                <div>
                  <section>
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
                        required={!Boolean(watchRole)}
                        showHelper
                        disabled={Boolean(s3UploadLocation)}
                      />
                    </UIFormField>

                    {watchRole && (
                      <>
                        <div className="box">
                          <h3>Option 1: Drag and Drop File</h3>
                          <WorkTabsPreservationFileSetDropzone
                            currentFile={currentFile}
                            acceptedFileTypes={acceptedFileTypes}
                            fileSetRole={watchRole}
                            handleRemoveFile={resetForm}
                            handleSetFile={handleSetFile}
                            uploadProgress={uploadProgress}
                            workTypeId={workTypeId}
                            disabled={uploadMethod === 's3'}
                          />
                        </div>

                        <div className="box">
                          <h3>Option 2: Choose from S3 Ingest Bucket</h3>
                          <S3ObjectPicker
                            onFiles={console.log} 
                            onFileSelect={handleSelectS3Object}
                            fileSetRole={watchRole}
                            workTypeId={workTypeId}
                            disabled={uploadMethod === 'dragdrop'}
                          />
                        </div>
                      </>
                    )}

                    {s3UploadLocation && (
                      <WorkTabsPreservationFileSetForm
                        s3UploadLocation={s3UploadLocation}
                      />
                    )}
                  </section>

                  <DialogFooter>
                    {s3UploadLocation && (
                      <>
                        <Button
                          isText
                          type="button"
                          onClick={handleCancel}
                          data-testid="cancel-button"
                        >
                          Cancel
                        </Button>
                        <Button
                          disabled={!s3UploadLocation}
                          isPrimary
                          type="submit"
                          data-testid="submit-button"
                        >
                          Ingest fileset
                        </Button>
                      </>
                    )}
                  </DialogFooter>
                </div>
              </form>
            </FormProvider>
          )}
        </DialogContent>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

WorkTabsPreservationFileSetModal.propTypes = {
  closeModal: PropTypes.func,
  isVisible: PropTypes.bool,
  workId: PropTypes.string,
  workTypeId: PropTypes.oneOf(["IMAGE", "AUDIO", "VIDEO"]),
};

export default WorkTabsPreservationFileSetModal;