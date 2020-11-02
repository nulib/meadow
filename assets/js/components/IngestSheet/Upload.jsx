import React, { useState } from "react";
import axios from "axios";
import PropTypes from "prop-types";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useHistory } from "react-router-dom";
import { GET_PROJECT } from "../Project/project.gql.js";
import { useMutation } from "@apollo/client";
import { CREATE_INGEST_SHEET } from "./ingestSheet.gql.js";
import { toastWrapper } from "../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm, FormProvider } from "react-hook-form";
import UIFormInput from "../UI/Form/Input.jsx";
import UIFormField from "../UI/Form/Field.jsx";
import { Button } from "@nulib/admin-react-components";

const IngestSheetUpload = ({ project, presignedUrl }) => {
  const history = useHistory();
  const methods = useForm();
  const [values, setValues] = useState({ file: "" });
  const [fileNameString, setFileNameString] = useState("No file uploaded");

  const [createIngestSheet, { data, loading, error }] = useMutation(
    CREATE_INGEST_SHEET,
    {
      onCompleted({ createIngestSheet }) {
        history.push(
          `/project/${project.id}/ingest-sheet/${createIngestSheet.id}`
        );
        toastWrapper(
          "is-success",
          `Ingest Sheet ${data.ingest_sheet_title} created successfully`
        );
      },
      onError() {
        setValues({ file: "" });
        setFileNameString("No file uploaded");
      },
      refetchQueries(mutationResult) {
        return [
          {
            query: GET_PROJECT,
            variables: { projectId: project.id },
          },
        ];
      },
    }
  );

  const handleInputChange = (event) => {
    event.persist();
    const { name, value } = event.target;
    setValues({ ...values, [name]: value });

    if (name === "file") {
      if (event.target.files.length > 0) {
        setFileNameString(event.target.files[0].name);
      }
    }
  };

  const handleCancel = (e) => {
    history.push(`/project/${project.id}`);
  };

  const onSubmit = async (data) => {
    if (values.file.length > 0) {
      await uploadToS3();
      await createIngestSheet({
        variables: {
          title: data.ingest_sheet_title,
          projectId: project.id,
          filename: `s3://${presignedUrl
            .split("?")[0]
            .split("/")
            .slice(-3)
            .join("/")}`,
        },
      });
    } else {
      toastWrapper(
        "is-danger",
        `Choose a file to ingest into ${data.ingest_sheet_title}`
      );
    }
  };

  const uploadToS3 = () => {
    return new Promise((resolve, _reject) => {
      const file = document.getElementById("file").files[0];
      const reader = new FileReader();
      reader.onload = (event) => {
        const headers = { "Content-Type": file.type };
        axios
          .put(presignedUrl, event.target.result, { headers: headers })
          .then((_) => resolve())
          .catch((error) => {
            console.log(error);
            toastWrapper("is-danger", `Error uploading file to S3: ${error}`);
            resolve();
          });
      };
      reader.readAsText(file);
    });
  };

  const { file } = values;

  if (loading) return <Loading />;

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit)}>
        <Error error={error} />
        <UIFormField label="Ingest Sheet Title">
          <UIFormInput
            isReactHookForm
            required
            label="Ingest Sheet Title"
            name="ingest_sheet_title"
            placeholder="Ingest Sheet Title"
          />
        </UIFormField>

        <div className="field">
          <div id="file-js-example" className="file has-name">
            <label className="file-label">
              <input
                className="file-input"
                id="file"
                name="file"
                type="file"
                onChange={handleInputChange}
              />
              <span className="file-cta">
                <span className="file-icon">
                  <FontAwesomeIcon icon="file-csv" />
                </span>
                <span className="file-label">Choose a file…</span>
              </span>
              <span className="file-name">{fileNameString}</span>
            </label>
          </div>
        </div>

        <div className="buttons is-right">
          <Button type="submit" isPrimary>
            <span className="icon">
              <FontAwesomeIcon icon="file-upload" />
            </span>
            <span>Upload</span>
          </Button>
          <Button isText onClick={handleCancel}>
            Cancel
          </Button>
        </div>
      </form>
    </FormProvider>
  );
};

IngestSheetUpload.propTypes = {
  project: PropTypes.object.isRequired,
  presignedUrl: PropTypes.string.isRequired,
};

export default IngestSheetUpload;
