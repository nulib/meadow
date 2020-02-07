import React, { useState } from "react";
import axios from "axios";
import PropTypes from "prop-types";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useHistory } from "react-router-dom";
import { GET_PROJECT } from "../Project/project.query";
import { useMutation } from "@apollo/react-hooks";
import { CREATE_INGEST_SHEET } from "./ingestSheet.query";
import { useToasts } from "react-toast-notifications";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const IngestSheetUpload = ({ projectId, presignedUrl }) => {
  const history = useHistory();
  const { addToast } = useToasts();
  const [values, setValues] = useState({ ingest_sheet_name: "", file: "" });
  const [fileNameString, setFileNameString] = useState("No file uploaded");
  const [createIngestSheet, { data, loading, error }] = useMutation(
    CREATE_INGEST_SHEET,
    {
      onCompleted({ createIngestSheet }) {
        history.push(
          `/project/${projectId}/ingest-sheet/${createIngestSheet.id}`
        );
      },
      refetchQueries(mutationResult) {
        return [
          {
            query: GET_PROJECT,
            variables: { projectId }
          }
        ];
      }
    }
  );

  const handleInputChange = event => {
    event.persist();
    const { name, value } = event.target;
    setValues({ ...values, [name]: value });

    if (name === "file") {
      if (event.target.files.length > 0) {
        setFileNameString(event.target.files[0].name);
      }
    }
  };

  const handleCancel = e => {
    history.push(`/project/${projectId}`);
  };

  const handleSubmit = async e => {
    e.preventDefault();
    await uploadToS3();
    await createIngestSheet({
      variables: {
        name: ingest_sheet_name,
        projectId: projectId,
        filename: `s3://${presignedUrl
          .split("?")[0]
          .split("/")
          .slice(-3)
          .join("/")}`
      }
    });
    console.log("done creating IngestSheet");
  };

  const uploadToS3 = async () => {
    try {
      const submitFile = async (data, headers) => {
        await axios.put(presignedUrl, data, { headers: headers });
      };

      const file = document.getElementById("file").files[0];
      const reader = new FileReader();
      reader.onload = event => {
        const headers = { "Content-Type": file.type };
        submitFile(event.target.result, headers);
      };
      reader.readAsText(file);
    } catch (error) {
      Promise.resolve(null);
      console.log(error);
      addToast(`Error uploading file to S3: ${error}`, {
        appearance: "error",
        autoDismiss: true
      });
    }
  };

  const { ingest_sheet_name, file } = values;

  const isSubmitDisabled = () => {
    return values.ingest_sheet_name.length === 0 || values.file.length === 0;
  };

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <div className="columns">
      <div className="column is-half is-offset-one-quarter">
        <form onSubmit={handleSubmit}>
          <Error error={error} />
          <div className="field">
            <label htmlFor="ingest_sheet_name" className="label">
              Ingest Sheet Name
            </label>
            <div className="control">
              <input
                id={"ingest_sheet_name"}
                name="ingest_sheet_name"
                type="text"
                className="input"
                onChange={handleInputChange}
              />
            </div>
          </div>
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
                    <FontAwesomeIcon icon="file-upload" />
                  </span>
                  <span className="file-label">Choose a file…</span>
                </span>
                <span className="file-name">{fileNameString}</span>
              </label>
            </div>
            {/* <div className="file">
              <label className="file-label">
                <input
                  className="file-input"
                  id={"file"}
                  name="file"
                  type="file"
                  onChange={handleInputChange}
                />
                <span className="file-cta">
                  <span className="file-icon">
                    <FontAwesomeIcon icon="file-upload" />
                  </span>
                  <span className="file-label">Choose a file…</span>
                </span>
              </label>
            </div> */}
          </div>

          <div className="buttons">
            <button
              type="submit"
              className="button is-primary"
              disabled={isSubmitDisabled()}
            >
              Submit
            </button>
            <button type="button" className="button" onClick={handleCancel}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

IngestSheetUpload.propTypes = {
  projectId: PropTypes.string.isRequired,
  presignedUrl: PropTypes.string.isRequired
};

export default IngestSheetUpload;
