import React from "react";
import PropTypes from "prop-types";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import DashboardsCsvImportModal from "@js/components/Dashboards/Csv/ImportModal";
import { CSV_METADATA_UPDATE_JOB } from "@js/components/Dashboards/dashboards.gql.js";
import { useMutation, useQuery } from "@apollo/client/react";
import { s3Location, toastWrapper } from "@js/services/helpers";
import { Button } from "@nulib/design-system";
import IconUpload from "@js/components/Icon/Upload";

function DashboardsCsvImport() {
  const [isModalOpen, setIsModalOpen] = React.useState(false);
  const [currentFile, setCurrentFile] = React.useState();

  const {
    loading: urlLoading,
    error: urlError,
    data: urlData,
  } = useQuery(GET_PRESIGNED_URL, {
    variables: { uploadType: "CSV_METADATA" },
    fetchPolicy: "no-cache",
  });

  const [csvMetadataUpdate, { data, loading, error }] = useMutation(
    CSV_METADATA_UPDATE_JOB,
    {
      onCompleted({ csvMetadataUpdate }) {
        toastWrapper(
          "is-success",
          `CSV file uploaded successfully, starting validation`
        );
        setCurrentFile(null);
        setIsModalOpen(false);
      },
      onError({ graphQLErrors, networkError }) {
        console.log("graphQLErrors", graphQLErrors);
        console.log("networkError", networkError);
        let errorStrings = [];
        if (graphQLErrors.length > 0) {
          errorStrings = graphQLErrors.map(
            ({ message, details }) =>
              `${message}: ${details && details.title ? details.title : ""}`
          );
        }
        toastWrapper("is-danger", errorStrings.join(" \n "));
        setCurrentFile(null);
        setIsModalOpen(false);
      },
    }
  );

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

  if (urlError) {
    return <p>Error loading presigned url</p>;
  }

  const handleImportCsv = () => {
    if (currentFile) {
      uploadToS3()
        .then(
          // Resolve callback
          () => {
            csvMetadataUpdate({
              variables: {
                filename: currentFile.name,
                source: s3Location(urlData.presignedUrl.url),
              },
            });
          },
          // Error callback
          (uploadToS3Error) => {
            console.error("uploadToS3Error", uploadToS3Error);
            toastWrapper(
              "is-danger",
              `Error uploading file to S3: ${uploadToS3Error}`
            );
            setCurrentFile(null);
            setIsModalOpen(false);
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

  return (
    <div data-testid="csv-job-import-wrapper">
      <Button
        isPrimary
        onClick={() => setIsModalOpen(true)}
        data-testid="import-csv-button"
      >
        <IconUpload />
        <span>Import CSV file</span>
      </Button>
      <DashboardsCsvImportModal
        currentFile={currentFile}
        isOpen={isModalOpen}
        handleImportCsv={handleImportCsv}
        handleClose={() => setIsModalOpen(false)}
        setCurrentFile={setCurrentFile}
      />
    </div>
  );
}

export default DashboardsCsvImport;
