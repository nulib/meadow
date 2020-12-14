import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { GET_WORK, INGEST_FILE_SET } from "@js/components/Work/work.gql.js";
import { useQuery, useMutation } from "@apollo/client";
import { s3Location, toastWrapper } from "@js/services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormSelect from "@js/components/UI/Form/Select.jsx";
import { FILE_SET_ROLES } from "@js/services/global-vars";
import UISkeleton from "@js/components/UI/Skeleton";
import WorkTabsPreservationFileSetDropzone from "@js/components/Work/Tabs/Preservation/FileSetDropzone";
import Error from "@js/components/UI/Error";

function FileSetModal({ closeModal, isHidden, workId }) {
  const [currentFile, setCurrentFile] = useState();
  const [fileUploadError, setFileUploadError] = useState();

  const defaultValues = {
    accessionNumber: "",
    label: "",
    description: "",
    role: "PM",
  };

  // React Hook form initialize
  const methods = useForm({
    defaultValues: defaultValues,
    shouldUnregister: false,
  });
  const { isSubmitting } = methods.formState;

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
          `FileSet record id: ${ingestFileSet.id} created successfully and ${ingestFileSet.metadata.original_filename} was submitted to the ingest pipeline.`
        );
        handleFormReset();
      },
      onError(error) {
        console.error("GQLerror", error);
      },
      refetchQueries(mutationResult) {
        return [
          {
            query: GET_WORK,
            variables: { id: workId },
          },
        ];
      },
    }
  );

  const handleFormReset = () => {
    methods.reset();
    setCurrentFile(null);
    closeModal();
    clearErrors();
  };

  const handleSetFile = (file) => {
    setCurrentFile(file);
  };

  const clearErrors = () => {
    setFileUploadError("");
  };

  const uploadFile = async () => {
    const response = await fetch(`${urlData.presignedUrl.url}`, {
      method: "PUT",
      headers: { "Content-Type": "multipart/form-data" },
      body: currentFile,
    });

    if (!response.ok) {
      throw new Error(response.statusText);
    }

    return response.url;
  };

  const onSubmit = async (data) => {
    // Explicitly returning (resolving/rejecting) a promise is needed for the spinner, and error displays to work
    return new Promise((resolve, reject) => {
      clearErrors();

      uploadFile()
        .then((url) => {
          ingestFileSet({
            variables: {
              accession_number: data.accessionNumber,
              workId,
              role: data.role,
              metadata: {
                description: data.description,
                label: data.label,
                original_filename: currentFile.name,
                location: s3Location(url),
              },
            },
          });
          return resolve();
        })
        .catch((error) => {
          console.error("Error uploading file to S3", error);
          setFileUploadError("Error uploading file to S3");
          return reject("File upload error");
        });
    });
  };

  if (urlLoading) return <p>Presigned URL Loading</p>;

  return (
    <div className={`modal ${isHidden ? "" : "is-active"}`}>
      {/* if there is a problem getting a presigned url don't show the form at all */}
      {urlError ? (
        <div className="notification is-danger">
          Error retrieving presigned url
        </div>
      ) : (
        <FormProvider {...methods}>
          <form
            onSubmit={methods.handleSubmit(onSubmit)}
            data-testid="fileset-form"
          >
            <div className="modal-background"></div>
            <div className="modal-card">
              <header className="modal-card-head">
                <p className="modal-card-title">Add FileSet to Work</p>
                <button
                  className="delete"
                  aria-label="close"
                  onClick={() => {
                    handleFormReset();
                  }}
                ></button>
              </header>
              <section className="modal-card-body">
                {fileUploadError && (
                  <div className="notification is-danger">
                    Error uploading file: {fileUploadError}
                  </div>
                )}
                {isSubmitting ? (
                  <UISkeleton rows={10} />
                ) : (
                  <div>
                    {error && <Error error={error} />}
                    <WorkTabsPreservationFileSetDropzone
                      currentFile={currentFile}
                      handleSetFile={handleSetFile}
                    />
                    <hr />

                    <UIFormField label="Accession number">
                      <UIFormInput
                        isReactHookForm
                        required
                        label="FileSet label"
                        data-testid="fileset-accession-number-input"
                        name="accessionNumber"
                        placeholder="accession number"
                      />
                    </UIFormField>

                    <UIFormField label="Label">
                      <UIFormInput
                        isReactHookForm
                        required
                        label="FileSet label"
                        data-testid="fileset-label-input"
                        name="label"
                        placeholder="Fileset label"
                      />
                    </UIFormField>

                    <UIFormField label="Description">
                      <UIFormInput
                        isReactHookForm
                        required
                        label="FileSet description"
                        data-testid="fileset-description-input"
                        name="description"
                        placeholder="Description of the Fileset"
                      />
                    </UIFormField>

                    <UIFormField label="Role">
                      <UIFormSelect
                        isReactHookForm
                        name="role"
                        label="Fileset Role"
                        options={FILE_SET_ROLES}
                        data-testid="fileset-role-input"
                      />
                    </UIFormField>
                  </div>
                )}
              </section>

              <footer className="modal-card-foot is-justify-content-flex-end">
                {isSubmitting || (
                  <>
                    <Button
                      isText
                      type="button"
                      onClick={() => {
                        handleFormReset();
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

FileSetModal.propTypes = {
  closeModal: PropTypes.func,
  isHidden: PropTypes.bool,
  workId: PropTypes.string,
};

export default FileSetModal;
