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
import {
  GET_WORK,
  REPLACE_FILE_SET,
} from "@js/components/Work/work.gql.js";
import React, { useEffect, useState } from "react";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import { getFileNameFromS3Uri, s3Location, toastWrapper } from "@js/services/helpers";
import { useLazyQuery, useMutation } from "@apollo/client/react";

import Error from "@js/components/UI/Error";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { IconAlert } from "@js/components/Icon";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UIIconText from "../../../UI/IconText";
import WorkTabsPreservationFileSetDropzone from "@js/components/Work/Tabs/Preservation/FileSetDropzone";
import S3ObjectPicker from "@js/components/Work/Tabs/Preservation/S3ObjectPicker"

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
  const [uploadMethod, setUploadMethod] = useState(null);

  const methods = useForm();

  const [
    getPresignedUrl,
    { error: urlError, loading: urlLoading, data: urlData },
  ] = useLazyQuery(GET_PRESIGNED_URL, {
    fetchPolicy: "no-cache",
    onCompleted: (data) => {
      uploadFile(data.presignedUrl.url);
    },
    onError(error) {
      console.error("error", error);
    },
  });

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
        console.error("error:", error);
        resetForm();
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

  useEffect(() => {
    if (fileset.id) {
      methods.setValue("label", fileset?.coreMetadata?.label || "");
      methods.setValue("description", fileset?.coreMetadata?.description || "");
    }
  }, [fileset.id]);

  const handleSubmit = (data) => {
    replaceFileSet({
      variables: {
        id: fileset.id,
        coreMetadata: {
          description: data.description,
          label: data.label,
          original_filename: currentFile?.name,
          location: s3UploadLocation,
        },
      },
    });
  };

  const resetForm = () => {
    setCurrentFile(null);
    setS3UploadLocation(null);
    setUploadProgress(0);
    setUploadError(null);
    setUploadMethod(null);
    methods.reset({
      label: fileset?.coreMetadata?.label || "",
      description: fileset?.coreMetadata?.description || "",
    });
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

  const handleSelectS3Object = (s3Object) => {
    setCurrentFile({
      location: s3Object.key,
      name: getFileNameFromS3Uri(s3Object.key),
    });
    setS3UploadLocation(s3Object.key);
    setUploadMethod('s3');
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
    <Dialog.Root open={isVisible} onOpenChange={handleCloseModal}>
      <Dialog.Portal>
        <DialogOverlay />
        <DialogContent data-testid="replace-file-sets">
          <DialogClose>
            <Icon isSmall aria-label="Close">
              <Icon.Close />
            </Icon>
          </DialogClose>
          <DialogTitle css={{ textAlign: "left" }}>
            Replace Fileset
          </DialogTitle>

          {urlError && (
            <div>
              <section>
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
                <div>
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

                    <div className="box">
                      <h3>Option 1: Drag and Drop File</h3>
                      <WorkTabsPreservationFileSetDropzone
                        currentFile={currentFile}
                        fileSetRole={fileset?.role?.id}
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
                        onFileSelect={handleSelectS3Object}
                        fileSetRole={fileset?.role?.id}
                        workTypeId={workTypeId}
                        defaultPrefix={"file_sets/"}
                        disabled={uploadMethod === 'dragdrop'}
                      />
                    </div>

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
                          isPrimary
                          disabled={!s3UploadLocation}
                          type="submit"
                          data-testid="submit-button"
                        >
                          Upload File
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

WorkTabsPreservationReplaceFileSet.propTypes = {
  closeModal: PropTypes.func,
  fileset: PropTypes.object,
  isVisible: PropTypes.bool,
  workId: PropTypes.string,
  workTypeId: PropTypes.oneOf(["IMAGE", "AUDIO", "VIDEO"]),
};

export default WorkTabsPreservationReplaceFileSet;