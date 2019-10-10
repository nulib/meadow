import React, { useState } from "react";
import axios from "axios";
import PropTypes from "prop-types";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { withRouter } from "react-router-dom";
import { GET_PROJECT } from "../Project/project.query";
import { useMutation } from "@apollo/react-hooks";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import { CREATE_INGEST_SHEET } from "./ingestSheet.query";
import { useToasts } from "react-toast-notifications";

const IngestSheetUpload = ({ projectId, presignedUrl, history }) => {
  const { addToast } = useToasts();
  const [values, setValues] = useState({ ingest_sheet_name: "", file: "" });
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
  };

  const handleCancel = e => {
    history.push(`/project/${projectId}`);
  };

  const handleSubmit = async e => {
    console.log("enters handleSubmit");
    e.preventDefault();
    await uploadToS3();
    console.log("upload to s3 done");
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
    <form onSubmit={handleSubmit}>
      <Error error={error} />
      <div className="mb-4">
        <label htmlFor="ingest_sheet_name">Ingest Sheet Name</label>
        <input
          id={"ingest_sheet_name"}
          name="ingest_sheet_name"
          type="text"
          className="text-input"
          onChange={handleInputChange}
        />
      </div>
      <div className="mb-4">
        <label htmlFor="file">Ingest Sheet File</label>
        <input
          id={"file"}
          name="file"
          type="file"
          onChange={handleInputChange}
        />
      </div>
      <UIButtonGroup>
        <UIButton type="submit" disabled={isSubmitDisabled()}>
          Submit
        </UIButton>
        <UIButton classes="btn-clear" onClick={handleCancel}>
          Cancel
        </UIButton>
      </UIButtonGroup>
    </form>
  );
};

IngestSheetUpload.propTypes = {
  history: PropTypes.shape({
    push: PropTypes.func.isRequired
  }).isRequired,
  projectId: PropTypes.string.isRequired,
  presignedUrl: PropTypes.string.isRequired
};

export default withRouter(IngestSheetUpload);
